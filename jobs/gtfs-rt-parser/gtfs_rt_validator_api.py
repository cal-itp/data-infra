"""
Downloads RT and related schedule data, and runs RT validator on the raw RT protobufs.
Writes gzipped JSONL output to GCS.
"""
import concurrent
import gzip
import json
import multiprocessing
import os
import shutil
import subprocess
import tempfile
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path
from typing import List, Tuple

import pandas as pd
import pendulum
import structlog as structlog
import typer
from calitp.config import get_bucket, is_development
from calitp.storage import get_fs
from structlog import configure
from structlog.threadlocal import merge_threadlocal

from gtfs_rt_parser import identify_files, RTFileType, RTFile, EXTENSION

configure(processors=[merge_threadlocal, structlog.processors.KeyValueRenderer()])

logger = structlog.get_logger()

JAR_DEFAULT = typer.Option(
    os.environ.get("GTFS_RT_VALIDATOR_JAR"),
    help="Path to the GTFS RT Validator JAR",
)

OUTPUT_BUCKET = "test-rt-validations" if is_development() else "rt-validations"

# Note that the final {extraction_date} is needed by the validator, which may read it as
# timestamp data. Note that the final datetime requires Z at the end, to indicate
# it's a ISO instant
RT_FILENAME_TEMPLATE = (
    "{extraction_date}__{itp_id}__{url_number}__{src_fname}__{extraction_date}Z.pb"
)


app = typer.Typer()


def download_gtfs_schedule_zip(gtfs_schedule_path, dst_path, fs):
    # fetch and zip gtfs schedule
    logger.info(f"Fetching gtfs schedule data from {gtfs_schedule_path} to {dst_path}")
    fs.get(gtfs_schedule_path, dst_path, recursive=True)
    try:
        os.remove(os.path.join(dst_path, "areas.txt"))
    except FileNotFoundError:
        pass
    shutil.make_archive(dst_path, "zip", dst_path)
    return f"{dst_path}.zip"


def download_rt_files(
    glob, rt_file_type, dst_folder, itp_id: int, url: int
) -> List[Tuple[RTFile, str]]:
    fs = get_fs()

    files = [
        file
        for file in identify_files(glob, rt_file_type)
        if file.itp_id == itp_id and file.url == url
    ]

    if not files:
        msg = "failed to find any rt files to download"
        logger.warn(msg)
        raise ValueError(msg)

    src_files = [file.path for file in files]
    # the RT validator expects file names to end in <extraction_time>Z; could probably do this with paths
    dst_files = [
        os.path.join(dst_folder, str(file.path) + f"__{file.tick}Z.pb")
        for file in files
    ]

    logger.info(f"downloading {len(files)} files from glob {glob}")

    fs.get(src_files, dst_files)
    return list(zip(files, dst_files))


@app.command()
def validate(gtfs_file, rt_path, jar_path: Path, verbose=False):
    logger.info(f"validating {gtfs_file} and {rt_path}")

    if not isinstance(gtfs_file, str):
        raise NotImplementedError("gtfs_file must be a string")

    stderr = subprocess.DEVNULL if not verbose else None
    stdout = subprocess.DEVNULL if not verbose else None

    subprocess.check_call(
        [
            "java",
            "-jar",
            str(jar_path),
            "-gtfs",
            gtfs_file,
            "-gtfsRealtimePath",
            rt_path,
            "-sort",
            "name",
        ],
        stderr=stderr,
        stdout=stdout,
    )


@app.command()
def validate_glob(
    file_type: RTFileType,
    gtfs_rt_glob: str,
    itp_id: int,
    url: int,
    gtfs_schedule_path: str,
    dst_bucket: str = OUTPUT_BUCKET,
    verbose: bool = False,
    jar_path: Path = JAR_DEFAULT,
    idx: int = None,
) -> None:
    fs = get_fs()

    with tempfile.TemporaryDirectory() as tmp_dir:
        dst_path_gtfs = f"{tmp_dir}/gtfs"
        dst_path_rt = f"{tmp_dir}/rt"
        files = download_rt_files(
            glob=gtfs_rt_glob,
            rt_file_type=file_type,
            dst_folder=dst_path_rt,
            itp_id=itp_id,
            url=url,
        )

        gtfs_zip = download_gtfs_schedule_zip(gtfs_schedule_path, dst_path_gtfs, fs=fs)

        logger.info(f"validating {len(files)} files")
        validate(gtfs_zip, dst_path_rt, jar_path=jar_path, verbose=verbose)

        for rt_file, downloaded_path in files:
            with tempfile.TemporaryDirectory(dir=tmp_dir) as gzip_tmp_dir:
                written = 0
                gzip_fname = str(gzip_tmp_dir + "/" + "temporary" + EXTENSION)

                # the validator outputs files with an added .results.json suffix
                with open(downloaded_path + ".results.json") as f:
                    records = json.load(f)
                with gzip.open(gzip_fname, "w") as gzipfile:
                    for record in records:
                        gzipfile.write((json.dumps(record) + "\n").encode("utf-8"))
                        written += 1
            out_path = f"{rt_file.validation_hive_path(dst_bucket)}{EXTENSION}"
            typer.echo(
                f"writing {written} validation result lines from {str(rt_file.path)} to {out_path}"
            )
            # put_with_retry(fs, gzip_fname, out_path)


@app.command()
def validate_gcs_bucket_many(
    param_csv: str = f"{get_bucket()}/rt-processed/calitp_validation_params/{pendulum.today().to_date_string()}.csv",
    dst_bucket=OUTPUT_BUCKET,
    verbose: bool = True,
    strict: bool = False,
    threads: int = 4,
    limit: int = None,
    jar_path: Path = JAR_DEFAULT,
):
    """Validate many gcs buckets using a parameter file.

    Additional Arguments:
        strict: whether to raise an error when a validation fails
        summary_path: directory for saving the status of validations
        result_name_prefix: a name to prefix to each result file name. File names
            will be numbered. E.g. result_0.parquet, result_1.parquet for two feeds.


    Param CSV should contain the following fields (passed to validate_gcs_bucket):
        * gtfs_schedule_path
        * gtfs_rt_glob_path

    The full parameters CSV is dumped to JSON with an additional column called
    is_status, which reports on whether or not the validation was succesfull.

    """
    if not jar_path:
        raise ValueError("Must set the environment variable GTFS_VALIDATOR_JAR")

    required_cols = [
        "calitp_itp_id",
        "calitp_url_number",
        "gtfs_schedule_path",
        "gtfs_rt_glob_path",
        "output_filename",
    ]

    logger.info(f"reading params from {param_csv}")
    fs = get_fs()
    with fs.open(param_csv) as f:
        params = pd.read_csv(f)

    if limit:
        logger.warn(f"limiting to {limit} rows")
        params = params.iloc[:limit]

    # check that the parameters file has all required columns
    missing_cols = set(required_cols) - set(params.columns)
    if missing_cols:
        raise ValueError("parameter csv missing columns: %s" % missing_cols)

    logger.info(f"processing {params.shape[0]} inputs with {threads} threads")

    # https://github.com/fsspec/gcsfs/issues/379#issuecomment-826887228
    # Note that this seems to differ per OS
    ctx = multiprocessing.get_context("spawn")

    exceptions = []

    # from https://stackoverflow.com/a/55149491
    # could be cleaned up a bit with a namedtuple
    with ProcessPoolExecutor(max_workers=threads, mp_context=ctx) as pool:
        futures = {
            pool.submit(
                validate_glob,
                # TODO: validation CSV has weird column names
                file_type=RTFileType[row["output_filename"]],
                dst_bucket=dst_bucket,
                gtfs_rt_glob=row["gtfs_rt_glob_path"],
                gtfs_schedule_path=row["gtfs_schedule_path"],
                verbose=verbose,
                idx=idx,
            ): row
            for idx, row in params.iterrows()
        }

        # Processes each future as it is completed, i.e. returned or errored
        for future in concurrent.futures.as_completed(futures):
            try:
                future.result()
            except Exception as e:
                if strict:
                    raise e
                exceptions.append(e)

    logger.info(
        f"finished multiprocessing; {params.shape[0] - len(exceptions)} successful of {params.shape[0]}"
    )

    if exceptions:
        msg = f"got {len(exceptions)} exceptions from processing {params.shape[0]} feeds: {exceptions}"
        typer.secho(msg, err=True, fg=typer.colors.RED)
        raise RuntimeError(msg)


if __name__ == "__main__":
    app()
