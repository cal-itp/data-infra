import os
import warnings
from contextlib import contextmanager
from functools import wraps
from pathlib import Path


class RequiresAdminWarning(UserWarning):
    """Represents errors where, e.g., a user tries to load a table to the warehouse."""


def is_development():
    options = {"development", "cal-itp-data-infra"}

    # if a person can write data, then they need to set AIRFLOW_ENV
    if is_pipeline():
        if "AIRFLOW_ENV" not in os.environ:
            raise KeyError(
                "Pipeline admin must set AIRFLOW_ENV env variable explicitly"
            )

        env = os.environ["AIRFLOW_ENV"]

        if env not in options:
            raise ValueError("AIRFLOW_ENV variable must be one of %s" % options)

    # otherwise, analysts connect to prod data by default
    else:
        env = os.environ.get("AIRFLOW_ENV", "cal-itp-data-infra")

    return env == "development"


def is_cloud():
    return os.environ.get("CALITP_AUTH") == "cloud"


def get_bucket():
    # TODO: can probably pull some of these behaviors into a config class
    if is_development():
        return "gs://gtfs-data-test"
    else:
        return "gs://gtfs-data"


def get_project_id():
    if is_development():
        return "cal-itp-data-infra-staging"

    return "cal-itp-data-infra"


def is_pipeline():
    return os.environ.get("CALITP_USER") == "pipeline"


def require_pipeline(func_name):
    """Decorator that skips a function is user is not admin.

    Note: this function is for convenience (not to replace appropriate access levels)
    """

    if not isinstance(func_name, str):
        raise TypeError("Warning must be a string")

    warning = f"Not running in pipeline, so skipping {func_name}()"

    def decorator(f):
        @wraps(f)
        def wrapper(*args, **kwargs):
            if not is_pipeline():
                warnings.warn(warning, RequiresAdminWarning)
            else:
                return f(*args, **kwargs)

        return wrapper

    return decorator


def format_table_name(name, is_staging=False, full_name=False):
    dataset, table_name = name.split(".")
    staging = "__staging" if is_staging else ""
    # test_prefix = "zzz_test_" if is_development() else ""
    test_prefix = ""

    project_id = get_project_id() + "." if full_name else ""
    # e.g. test_gtfs_schedule__staging.agency

    return f"{project_id}{test_prefix}{dataset}.{table_name}{staging}"


def pipe_file_name(path):
    """Returns absolute path for a file in the pipeline (e.g. the data folder)."""

    # For now, we just get the path relative to the directory holding the
    # DAGs folder. For some reason, gcp doesn't expose the same variable
    # for this folder, so need to handle differently on dev.
    if is_development():
        root = Path(os.environ["AIRFLOW__CORE__DAGS_FOLDER"]).parent
    else:
        root = Path(os.environ["DAGS_FOLDER"]).parent

    return str(root / path)


@contextmanager
def pipeline_context():
    """Temporarily set CALITP_USER to be pipeline.

    This allows a user to write to tables on production and staging.
    """

    prev_user = os.environ.get("CALITP_USER")

    os.environ["CALITP_USER"] = "pipeline"

    try:
        yield
    finally:
        if prev_user is None:
            del os.environ["CALITP_USER"]
        else:
            os.environ["CALITP_USER"] = prev_user
