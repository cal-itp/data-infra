"""Macros for Operators"""
import os

data_infra_macros = {
    "image_tag": lambda: "development"
    if os.environ["AIRFLOW_ENV"] == "development"
    else "latest",
    "get_project_id": lambda: "cal-itp-data-infra-staging"
    if os.environ["AIRFLOW_ENV"] == "development"
    else "cal-itp-data-infra",
    "env_var": os.getenv,
}
