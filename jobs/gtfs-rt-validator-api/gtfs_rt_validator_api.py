__version__ = "0.0.5"

import concurrent
import json
import multiprocessing
import os
import shutil
import subprocess
import traceback
from collections import defaultdict
from concurrent.futures import ProcessPoolExecutor
from pathlib import Path
from tempfile import NamedTemporaryFile, TemporaryDirectory

import gcsfs
import pandas as pd
import pendulum
import structlog as structlog
import typer
from calitp.config import get_bucket
from structlog import configure
from structlog.threadlocal import bind_threadlocal, clear_threadlocal, merge_threadlocal

configure(processors=[merge_threadlocal, structlog.processors.KeyValueRenderer()])

logger = structlog.get_logger()

RT_BUCKET_FOLDER = "gs://gtfs-data/rt"
RT_BUCKET_PROCESSED_FOLDER = "gs://gtfs-data/rt-processed"
SCHEDULE_BUCKET_FOLDER = "gs://gtfs-data/schedule"

# Note that the final {extraction_date} is needed by the validator, which may read it as
# timestamp data. Note that the final datetime requires Z at the end, to indicate
# it's a ISO instant
RT_FILENAME_TEMPLATE = (
    "{extraction_date}__{itp_id}__{url_number}__{src_fname}__{extraction_date}Z.pb"
)
N_THREAD_WORKERS = 30

try:
    JAR_PATH = os.environ["GTFS_VALIDATOR_JAR"]
except KeyError:
    raise Exception("Must set the environment variable GTFS_VALIDATOR_JAR")

# https://typer.tiangolo.com/
app = typer.Typer()

# Utility funcs ----


def json_to_newline_delimited(in_file, out_file):
    data = json.load(open(in_file))
    with open(out_file, "w") as f:
        f.write("\n".join([json.dumps(record) for record in data]))


def parse_pb_name_data(file_name):
    """Returns data encoded in extraction files, such as datetime or itp id.

    >>> parse_pb_name_data("2021-01-01__1__0__filename__etc")
    {'extraction_date': '2021-01-01', 'itp_id': 1, 'url_number': 0, 'src_fname': 'filename'}

    """

    extraction_date, itp_id, url_number, src_fname, *_ = Path(file_name).name.split(
        "__"
    )
    return dict(
        extraction_date=extraction_date,
        itp_id=int(itp_id),
        url_number=int(url_number),
        src_fname=src_fname,
    )


def build_pb_validator_name(extraction_date, itp_id, url_number, src_fname):
    """Return name for file in the format needed for validation.

    Note that the RT validator needs to use timestamps at the end of the filename,
    so this function ensures they are present.

    """

    return RT_FILENAME_TEMPLATE.format(
        extraction_date=extraction_date,
        itp_id=itp_id,
        url_number=url_number,
        src_fname=src_fname,
    )


# Validation ==================================================================


def gather_results(rt_path):
    # TODO: complete functionality to unpack results into a DataFrame
    # Path(rt_path).glob("*.results.json")
    raise NotImplementedError()


@app.command()
def validate(gtfs_file, rt_path, verbose=False):
    logger.info(f"validating {gtfs_file} and {rt_path}")

    if not isinstance(gtfs_file, str):
        raise NotImplementedError("gtfs_file must be a string")

    stderr = subprocess.DEVNULL if not verbose else None
    stdout = subprocess.DEVNULL if not verbose else None

    subprocess.check_call(
        [
            "java",
            "-jar",
            JAR_PATH,
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
def validate_gcs_bucket(
    project_id,
    token,
    gtfs_schedule_path,
    gtfs_rt_glob_path: str = None,
    out_dir: str = None,
    results_bucket: str = None,
    verbose: bool = False,
    aggregate_counts: bool = False,
    idx: int = None,
):
    """
    Fetch and validate GTFS RT data held in a google cloud bucket.

    Parameters:
        project_id: name of google cloud project.
        token: token argument passed to gcsfs.GCSFileSystem.
        gtfs_schedule_path: path to a folder holding unpacked GTFS schedule data.
        gtfs_rt_glob_path: path that GCSFileSystem.glob can uses to list all RT files.
            Note that this is assumed to have the form {datetime}/{itp_id}/{url_number}/filename.
        out_dir: a directory to store fetched files and results in.
        results_bucket: a bucket path to copy results to.
        verbose: whether to print helpful messages along the way.
        aggregate_counts: tbd

    Note that if out_dir is unspecified, the validation occurs in a temporary directory.

    """
    # TODO: get python 3.9
    clear_threadlocal()
    bind_threadlocal(
        idx=idx,
        gtfs_schedule_path=gtfs_schedule_path,
        gtfs_rt_glob_path=gtfs_rt_glob_path,
        out_dir=out_dir,
        result_bucket=results_bucket,
    )
    logger.debug("entering validate_gcs_bucket")

    logger.debug("getting gcs file system")
    fs = gcsfs.GCSFileSystem(project_id, token=token)
    logger.debug("got gcs file system")

    if not out_dir:
        tmp_dir = TemporaryDirectory()
        tmp_dir_name = tmp_dir.name
    else:
        tmp_dir = None
        tmp_dir_name = out_dir

    if results_bucket and not aggregate_counts and results_bucket.endswith("/"):
        results_bucket = f"{results_bucket}/"

    final_json_dir = Path(tmp_dir_name) / "newline_json"

    try:
        dst_path_gtfs = f"{tmp_dir_name}/gtfs"
        dst_path_rt = f"{tmp_dir_name}/rt"

        # fetch rt data
        if gtfs_rt_glob_path is None:
            raise ValueError("One of gtfs rt glob path or date must be specified")

        num_files = download_rt_files(dst_path_rt, fs, glob_path=gtfs_rt_glob_path)

        # fetch and zip gtfs schedule
        download_gtfs_schedule_zip(gtfs_schedule_path, dst_path_gtfs, fs)

        logger.info(f"validating {num_files} files")
        validate(f"{dst_path_gtfs}.zip", dst_path_rt, verbose=verbose)

        if results_bucket and aggregate_counts:
            logger.info(f"Saving aggregate counts as: {results_bucket}")

            error_counts = rollup_error_counts(dst_path_rt)

            if error_counts:
                df = pd.DataFrame(error_counts)

                with NamedTemporaryFile() as tmp_file:
                    df.to_parquet(tmp_file.name)
                    fs.put(tmp_file.name, results_bucket)

        elif results_bucket and not aggregate_counts:
            # validator stores results as {filename}.results.json
            logger.info(f"Putting data into results bucket: {results_bucket}")

            # fetch all results files created by the validator
            all_results = list(Path(dst_path_rt).glob("*.results.json"))

            final_json_dir.mkdir(exist_ok=True)
            final_files = []
            for result in all_results:
                # we appended a final timestamp to the files so that the validator
                # can use it to order them during validation. here, we remove that
                # timestamp, so we can use a single wildcard to select, eg..
                # *trip_updates.results.json
                result_out = "__".join(result.name.split("__")[:-1])

                json_to_newline_delimited(result, final_json_dir / result_out)
                final_files.append(final_json_dir / result_out)

            fs.put(final_files, results_bucket)

    except Exception as e:
        typer.echo(f"got exception during validation: {traceback.format_exc()}")
        raise e

    finally:
        if isinstance(tmp_dir, TemporaryDirectory):
            tmp_dir.cleanup()


@app.command()
def validate_gcs_bucket_many(
    project_id: str = "cal-itp-data-infra",
    token: str = None,  # "cloud",
    param_csv: str = f"{get_bucket()}/rt-processed/calitp_validation_params/{pendulum.today().to_date_string()}.csv",
    results_bucket: str = f"{get_bucket()}/rt-processed/validation/{pendulum.today().to_date_string()}",
    verbose: bool = True,
    aggregate_counts: bool = True,
    summary_path: str = f"{get_bucket()}/rt-processed/validation/{pendulum.today().to_date_string()}/summary.json",
    strict: bool = False,
    result_name_prefix: str = "validation_results",
    threads: int = 1,
    limit: int = None,
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

    import gcsfs

    required_cols = [
        "calitp_itp_id",
        "calitp_url_number",
        "gtfs_schedule_path",
        "gtfs_rt_glob_path",
        "output_filename",
    ]

    logger.info(f"reading params from {param_csv}")
    fs = gcsfs.GCSFileSystem(project_id, token=token)
    params = pd.read_csv(fs.open(param_csv))

    if limit:
        logger.warn(f"limiting to {limit} rows")
        params = params.iloc[:limit]

    # check that the parameters file has all required columns
    missing_cols = set(required_cols) - set(params.columns)
    if missing_cols:
        raise ValueError("parameter csv missing columns: %s" % missing_cols)

    statuses = []

    logger.info(f"processing {params.shape[0]} inputs with {threads} threads")

    # https://github.com/fsspec/gcsfs/issues/379#issuecomment-826887228
    # Note that this seems to differ per OS
    ctx = multiprocessing.get_context("spawn")

    # from https://stackoverflow.com/a/55149491
    # could be cleaned up a bit with a namedtuple
    with ProcessPoolExecutor(max_workers=threads, mp_context=ctx) as pool:
        futures = {
            pool.submit(
                validate_gcs_bucket,
                project_id,
                token,
                verbose=verbose,
                # TODO: os.path.join() would be better probably
                results_bucket=results_bucket
                + f"/{result_name_prefix}/{row['calitp_itp_id']}/{row['calitp_url_number']}/{row['output_filename']}.parquet",
                aggregate_counts=aggregate_counts,
                idx=idx,
                gtfs_schedule_path=row["gtfs_schedule_path"],
                gtfs_rt_glob_path=row["gtfs_rt_glob_path"],
            ): row
            for idx, row in params.iterrows()
        }

        # Processes each future as it is completed, i.e. returned or errored
        for future in concurrent.futures.as_completed(futures):
            row = futures[future]
            # result() will throw an exception if one occurred in the underlying function
            try:
                future.result()
            except Exception as e:
                if strict:
                    raise e
                statuses.append({**row, "is_success": False, "exc": str(e)})
            else:
                statuses.append({**row, "is_success": True})

    successes = sum(s["is_success"] for s in statuses)

    logger.info(f"finished multiprocessing; {successes} successful of {len(statuses)}")

    summary_ndjson = "\n".join([json.dumps(record) for record in statuses])

    if summary_path:
        fs.pipe(summary_path, summary_ndjson.encode())


def download_gtfs_schedule_zip(gtfs_schedule_path, dst_path, fs):
    # fetch and zip gtfs schedule
    logger.info(f"Fetching gtfs schedule data from {gtfs_schedule_path} to {dst_path}")
    fs.get(gtfs_schedule_path, dst_path, recursive=True)
    try:
        os.remove(os.path.join(dst_path, "areas.txt"))
    except FileNotFoundError:
        pass
    shutil.make_archive(dst_path, "zip", dst_path)


def download_rt_files(dst_dir, fs=None, date="2021-08-01", glob_path=None) -> int:
    """Download all files for an GTFS RT feed (or multiple feeds)

    If date is specified, downloads daily data for all feeds. Otherwise, if
    glob_path is specified, downloads data for a single feed.

    Parameters:
        date: date of desired feeds to download data from (e.g. 2021-09-01)
        glob_path: if specified, the path (including a wildcard) for downloading a
                   single feed.

    """
    if fs is None:
        raise NotImplementedError("Must specify fs")

    # {date}T{timestamp}/{itp_id}/{url_number}
    all_files = (
        fs.glob(glob_path)
        if glob_path
        else fs.glob(f"{RT_BUCKET_FOLDER}/{date}*/*/*/*")
    )

    to_copy = []
    out_feeds = defaultdict(lambda: [])
    for src_path in all_files:
        dt, itp_id, url_number, src_fname = src_path.split("/")[-4:]
        if glob_path:
            dst_parent = Path(dst_dir)
        else:
            # if we are downloading multiple feeds, make each feed a subdir
            dst_parent = Path(dst_dir) / itp_id / url_number

        dst_parent.mkdir(parents=True, exist_ok=True)

        out_fname = build_pb_validator_name(dt, itp_id, url_number, src_fname)

        dst_name = str(dst_parent / out_fname)

        to_copy.append([src_path, dst_name])
        out_feeds[(itp_id, url_number)].append(dst_name)

    if not to_copy:
        msg = "failed to find any rt files to download"
        logger.warn(msg)
        raise ValueError(msg)

    logger.info(f"downloading {len(to_copy)} files with glob_path {glob_path}")

    src_files, dst_files = zip(*to_copy)
    fs.get(list(src_files), list(dst_files))
    return len(to_copy)


# Rectangling =================================================================


def rollup_error_counts(rt_dir):
    result_files = Path(rt_dir).glob("*.results.json")

    code_counts = []
    for path in result_files:
        metadata = parse_pb_name_data(path)

        result_json = json.load(path.open())
        for entry in result_json:
            code_counts.append(
                {
                    "calitp_itp_id": metadata["itp_id"],
                    "calitp_url_number": metadata["url_number"],
                    "calitp_extracted_at": metadata["extraction_date"],
                    "rt_feed_type": metadata["src_fname"],
                    "error_id": entry["errorMessage"]["validationRule"]["errorId"],
                    "n_occurrences": len(entry["occurrenceList"]),
                }
            )

    return code_counts


if __name__ == "__main__":
    app()
