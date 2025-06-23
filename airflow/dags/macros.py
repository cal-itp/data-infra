"""Macros for Operators"""
import os

data_infra_macros = {
    "image_tag": lambda: "development"
    if os.environ["AIRFLOW_ENV"] == "development"
    else "latest",
    "env_var": os.environ.get,
}
