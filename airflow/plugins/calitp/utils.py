import os


def is_development():
    options = {"development", "cal-itp-data-infra"}

    if os.environ["AIRFLOW_ENV"] not in options:
        raise ValueError("AIRFLOW_ENV variable must be one of %s" % options)

    return os.environ["AIRFLOW_ENV"] == "development"


def get_bucket():
    # TODO: can probably pull some of these behaviors into a config class
    return os.environ["AIRFLOW_VAR_EXTRACT_BUCKET"]


def get_project_id():
    return "cal-itp-data-infra"


def format_table_name(name, is_staging=False, full_name=False):
    dataset, table_name = name.split(".")
    staging = "__staging" if is_staging else ""
    test_prefix = "test_" if is_development() else ""

    project_id = get_project_id() + "." if full_name else ""
    # e.g. test_gtfs_schedule__staging.agency

    return f"{project_id}{test_prefix}{dataset}.{table_name}{staging}"
