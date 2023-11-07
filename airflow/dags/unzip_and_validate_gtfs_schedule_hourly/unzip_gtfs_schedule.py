# ---
# python_callable: airflow_unzip_extracts
# provide_context: true
# ---
import concurrent
import hashlib
import logging
import os
import zipfile
from concurrent.futures import Future, ThreadPoolExecutor
from io import BytesIO
from typing import ClassVar, Dict, List, Optional, Tuple

import pendulum
import sentry_sdk
import typer
from calitp_data_infra.storage import (
    GTFSFeedType,
    GTFSScheduleFeedExtract,
    PartitionedGCSArtifact,
    ProcessingOutcome,
    get_fs,
)
from tqdm import tqdm
from utils import (
    SCHEDULE_UNZIPPED_BUCKET_HOURLY,
    GTFSScheduleFeedFileHourly,
    get_schedule_files_in_hour,
)

SCHEDULE_RAW_BUCKET = os.environ["CALITP_BUCKET__GTFS_SCHEDULE_RAW"]
GTFS_UNZIP_LIST_ERROR_THRESHOLD = float(
    os.getenv("GTFS_UNZIP_LIST_ERROR_THRESHOLD", 0.99)
)
MACOSX_ZIP_FOLDER = "__MACOSX"


def log(*args, err=False, fg=None, pbar=None, **kwargs):
    # capture fg so we don't pass it to pbar
    if pbar:
        pbar.write(*args, **kwargs)
    else:
        typer.secho(*args, err=err, fg=fg, **kwargs)


class GTFSScheduleFeedExtractUnzipOutcome(ProcessingOutcome):
    extract: GTFSScheduleFeedExtract
    zipfile_extract_md5hash: Optional[str]
    zipfile_files: Optional[List[str]]
    zipfile_dirs: Optional[List[str]]
    extracted_files: Optional[List[GTFSScheduleFeedFileHourly]]


class ScheduleUnzipResult(PartitionedGCSArtifact):
    bucket: ClassVar[str] = SCHEDULE_UNZIPPED_BUCKET_HOURLY
    table: ClassVar[str] = "unzipping_results"
    partition_names: ClassVar[List[str]] = ["dt", "ts"]
    ts: pendulum.DateTime
    outcomes: List[GTFSScheduleFeedExtractUnzipOutcome]

    @property
    def dt(self):
        return self.ts.date()

    @property
    def successes(self) -> List[GTFSScheduleFeedExtractUnzipOutcome]:
        return [outcome for outcome in self.outcomes if outcome.success]

    @property
    def failures(self) -> List[GTFSScheduleFeedExtractUnzipOutcome]:
        return [outcome for outcome in self.outcomes if not outcome.success]

    def save(self, fs):
        self.save_content(
            fs=fs,
            content="\n".join(o.json() for o in self.outcomes).encode(),
            exclude={"outcomes"},
        )


def summarize_zip_contents(
    zip: zipfile.ZipFile,
    at: str = "",
    pbar=None,
) -> Tuple[List[str], List[str], bool]:
    files = []
    directories = []
    for entry in zip.namelist():
        if zipfile.Path(zip, at=entry).is_file():
            files.append(entry)
        if zipfile.Path(zip, at=entry).is_dir():
            directories.append(entry)
    log(f"Found files: {files} and directories: {directories}", pbar=pbar)
    # the only valid case for any directory inside the zipfile is if there's exactly one
    # and it's the only item at the root of the zipfile(in which case we can treat that
    # directory's contents as the feed)
    # we want to exclude __MACOSX directories from this calculation
    # see https://superuser.com/questions/104500/what-is-macosx-folder
    is_valid = (not directories) or (
        (len(directories) == 1)
        and (
            [
                item.is_dir()
                for item in zipfile.Path(zip, at="").iterdir()
                if item.name != MACOSX_ZIP_FOLDER
            ]
            == [True]
        )
    )
    return files, directories, is_valid


def process_feed_files(
    fs,
    extract: GTFSScheduleFeedExtract,
    zip: zipfile.ZipFile,
    files: List[str],
    directories: List[str],
    is_valid: bool,
    pbar=None,
) -> Tuple[List[GTFSScheduleFeedFileHourly], str]:
    zipfile_files = []
    md5hash = hashlib.md5()
    if not is_valid:
        raise ValueError(
            "Unparseable zip: File/directory structure within zipfile cannot be unpacked"
        )

    # sort to make the hash deterministic
    for file in sorted(
        [file for file in files if not file.startswith(MACOSX_ZIP_FOLDER)]
    ):
        # make a proper path to access the .name attribute later
        file_path = zipfile.Path(zip, at=file)
        with zip.open(file) as f:
            file_content = f.read()
        file_extract = GTFSScheduleFeedFileHourly(
            ts=extract.ts,
            extract_config=extract.config,
            original_filename=file,
            # only replace slashes so that this is a mostly GCS-filepath-safe string
            # if we encounter something else, we will address: https://cloud.google.com/storage/docs/naming-objects
            filename=file_path.name.replace("/", "__"),
        )
        md5hash.update(file_content)
        file_extract.save_content(content=file_content, fs=fs)
        zipfile_files.append(file_extract)
    return zipfile_files, md5hash.hexdigest()


def unzip_individual_feed(
    i: int,
    extract: GTFSScheduleFeedExtract,
    pbar=None,
) -> GTFSScheduleFeedExtractUnzipOutcome:
    log(f"processing i={i} {extract.name}", pbar=pbar)
    fs = get_fs()
    zipfile_md5_hash = None
    files = []
    directories = []
    try:
        with fs.open(extract.path) as f:
            zipf = zipfile.ZipFile(BytesIO(f.read()))
        files, directories, is_valid = summarize_zip_contents(zipf, pbar=pbar)
        zipfile_files, zipfile_md5_hash = process_feed_files(
            fs,
            extract,
            zipf,
            files,
            directories,
            is_valid,
            pbar=pbar,
        )
    except Exception as e:
        log(f"Can't process {extract.path}: {type(e)} {e}", pbar=pbar)
        with sentry_sdk.push_scope() as scope:
            scope.fingerprint = [extract.config.url, str(e)]
            scope.set_context("extract", extract.dict())
            sentry_sdk.capture_exception(e)
        return GTFSScheduleFeedExtractUnzipOutcome(
            success=False,
            extract=extract,
            zipfile_extract_md5hash=zipfile_md5_hash,
            exception=e,
            zipfile_files=files,
            zipfile_dirs=directories,
        )
    return GTFSScheduleFeedExtractUnzipOutcome(
        success=True,
        extract=extract,
        zipfile_extract_md5hash=zipfile_md5_hash,
        zipfile_files=files,
        zipfile_dirs=directories,
        extracted_files=zipfile_files,
    )


def unzip_extracts(
    data_interval_start: pendulum.DateTime,
    data_interval_end: pendulum.DateTime,
    threads: int = 4,
    progress: bool = False,
):
    period = data_interval_end.subtract(microseconds=1) - data_interval_start
    typer.secho(f"unzipping extracts in period {period}", fg=typer.colors.MAGENTA)

    fs = get_fs()

    extract_map = get_schedule_files_in_hour(
        cls=GTFSScheduleFeedExtract,
        bucket=SCHEDULE_RAW_BUCKET,
        table=GTFSFeedType.schedule,
        period=period,
    )

    if not extract_map:
        typer.secho(
            "WARNING: found 0 extracts to process, exiting",
            fg=typer.colors.YELLOW,
        )
        return

    for ts, extracts in extract_map.items():
        typer.secho(
            f"processing extract {ts}",
            fg=typer.colors.MAGENTA,
        )
        outcomes = []
        pbar = tqdm(total=len(extracts)) if progress else None

        with ThreadPoolExecutor(max_workers=threads) as pool:
            futures: Dict[Future, GTFSScheduleFeedExtract] = {
                pool.submit(
                    unzip_individual_feed, i=i, extract=extract, pbar=pbar
                ): extract
                for i, extract in enumerate(extracts)
            }

            for future in concurrent.futures.as_completed(futures):
                if pbar:
                    pbar.update(1)
                # TODO: could consider letting errors bubble up and handling here
                outcomes.append(future.result())

        if pbar:
            del pbar

        result = ScheduleUnzipResult(filename="results.jsonl", ts=ts, outcomes=outcomes)
        result.save(fs)

        assert len(extracts) == len(
            result.outcomes
        ), f"ended up with {len(outcomes)} outcomes from {len(extracts)} extracts"

        success_rate = len(result.successes) / len(extracts)
        exceptions = [
            (failure.exception, failure.extract.config.url)
            for failure in result.failures
        ]
        exc_str = "\n".join(str(tup) for tup in exceptions)
        msg = f"got {len(exceptions)} exceptions from validating {len(extracts)} extracts:\n{exc_str}"  # noqa: E231
        if exceptions:
            typer.secho(msg, err=True, fg=typer.colors.RED)
        if success_rate < GTFS_UNZIP_LIST_ERROR_THRESHOLD:
            raise RuntimeError(msg)


def airflow_unzip_extracts(
    data_interval_start: pendulum.DateTime,
    data_interval_end: pendulum.DateTime,
    **kwargs,
):
    sentry_sdk.init()
    unzip_extracts(
        data_interval_start,
        data_interval_end,
        threads=2,
        progress=True,
    )


if __name__ == "__main__":
    # for testing
    logging.basicConfig(level=logging.INFO)
    unzip_extracts(pendulum.datetime(1901, 1, 1))
