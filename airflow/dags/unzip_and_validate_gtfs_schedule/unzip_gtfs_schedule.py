# ---
# python_callable: airflow_unzip_extracts
# provide_context: true
# ---
import concurrent
import logging
import os
from concurrent.futures import ThreadPoolExecutor, Future

import pendulum
import zipfile

from io import BytesIO
from typing import ClassVar, List, Optional, Tuple, Dict

import typer
from calitp.storage import (
    fetch_all_in_partition,
    GTFSScheduleFeedExtract,
    get_fs,
    GTFSFeedType,
    PartitionedGCSArtifact,
    ProcessingOutcome,
)
from tqdm import tqdm

from utils import GTFSScheduleFeedFile

SCHEDULE_UNZIPPED_BUCKET = os.environ["CALITP_BUCKET__GTFS_SCHEDULE_UNZIPPED"]
SCHEDULE_RAW_BUCKET = os.environ["CALITP_BUCKET__GTFS_SCHEDULE_RAW"]


def log(*args, err=False, fg=None, pbar=None, **kwargs):
    # capture fg so we don't pass it to pbar
    if pbar:
        pbar.write(*args, **kwargs)
    else:
        typer.secho(*args, err=err, fg=fg, **kwargs)


class GTFSScheduleFeedExtractUnzipOutcome(ProcessingOutcome):
    zipfile_extract_path: str
    zipfile_extract_md5hash: Optional[str]
    zipfile_files: Optional[List[str]]
    zipfile_dirs: Optional[List[str]]
    extracted_files: Optional[List[str]]


class ScheduleUnzipResult(PartitionedGCSArtifact):
    bucket: ClassVar[str] = SCHEDULE_UNZIPPED_BUCKET
    table: ClassVar[str] = "unzipping_results"
    partition_names: ClassVar[List[str]] = ["dt"]
    dt: pendulum.Date
    outcomes: List[GTFSScheduleFeedExtractUnzipOutcome]

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
    # the only valid case for any directory inside the zipfile is if there's exactly one and it's the only item at the root of the zipfile
    # (in which case we can treat that directory's contents as the feed)
    is_valid = (not directories) or (
        (len(directories) == 1)
        and ([item.is_dir() for item in zipfile.Path(zip, at="").iterdir()] == [True])
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
):
    zipfile_files = []
    if not is_valid:
        raise ValueError(
            "Unparseable zip: File/directory structure within zipfile cannot be unpacked"
        )

    for file in files:
        # make a proper path to access the .name attribute later
        file_path = zipfile.Path(zip, at=file)
        with zip.open(file) as f:
            file_content = f.read()
        file_extract = GTFSScheduleFeedFile(
            ts=extract.ts,
            extract_config=extract.config,
            zipfile_path=extract.path,
            original_filename=file,
            # only replace slashes so that this is a mostly GCS-filepath-safe string
            # if we encounter something else, we will address: https://cloud.google.com/storage/docs/naming-objects
            filename=file_path.name.replace("/", "__"),
        )
        file_extract.save_content(content=file_content, fs=fs)
        zipfile_files.append(file_extract)
    return zipfile_files


def unzip_individual_feed(
    i: int,
    extract: GTFSScheduleFeedExtract,
    pbar=None,
) -> GTFSScheduleFeedExtractUnzipOutcome:
    log(f"processing i={i} {extract.name}", pbar=pbar)
    fs = get_fs()
    zipfile_md5_hash = ""
    files = []
    directories = []
    try:
        with fs.open(extract.path) as f:
            zipfile_md5_hash = f.info()["md5Hash"]
            zip = zipfile.ZipFile(BytesIO(f.read()))
        files, directories, is_valid = summarize_zip_contents(zip, pbar=pbar)
        zipfile_files = process_feed_files(
            fs,
            extract,
            zip,
            files,
            directories,
            is_valid,
            pbar=pbar,
        )
    except Exception as e:
        log(f"Can't process {extract.path}: {e}", pbar=pbar)
        return GTFSScheduleFeedExtractUnzipOutcome(
            success=False,
            zipfile_extract_md5hash=zipfile_md5_hash,
            zipfile_extract_path=extract.path,
            exception=e,
            zipfile_files=files,
            zipfile_dirs=directories,
        )
    return GTFSScheduleFeedExtractUnzipOutcome(
        success=True,
        zipfile_extract_md5hash=zipfile_md5_hash,
        zipfile_extract_path=extract.path,
        zipfile_files=files,
        zipfile_dirs=directories,
        extracted_files=[file.path for file in zipfile_files],
    )


def unzip_extracts(
    day: pendulum.datetime,
    threads: int = 4,
    progress: bool = False,
):
    fs = get_fs()
    day = pendulum.instance(day).date()
    extracts = fetch_all_in_partition(
        cls=GTFSScheduleFeedExtract,
        bucket=SCHEDULE_RAW_BUCKET,
        table=GTFSFeedType.schedule,
        fs=fs,
        partitions={
            "dt": day,
        },
        verbose=True,
    )

    logging.info(f"Identified {len(extracts)} records for {day}")
    outcomes = []
    pbar = tqdm(total=len(extracts)) if progress else None

    with ThreadPoolExecutor(max_workers=threads) as pool:
        futures: Dict[Future, GTFSScheduleFeedExtract] = {
            pool.submit(unzip_individual_feed, i=i, extract=extract, pbar=pbar): extract
            for i, extract in enumerate(extracts)
        }

        for future in concurrent.futures.as_completed(futures):
            if pbar:
                pbar.update(1)
            # TODO: could consider letting errors bubble up and handling here
            outcomes.append(future.result())

    if pbar:
        del pbar

    result = ScheduleUnzipResult(filename="results.jsonl", dt=day, outcomes=outcomes)
    result.save(fs)

    assert len(extracts) == len(
        result.outcomes
    ), f"ended up with {len(outcomes)} outcomes from {len(extracts)} extracts"


def airflow_unzip_extracts(task_instance, execution_date, **kwargs):
    unzip_extracts(execution_date, threads=2, progress=True)


if __name__ == "__main__":
    # for testing
    logging.basicConfig(level=logging.INFO)
    unzip_extracts(pendulum.datetime(1901, 1, 1))
