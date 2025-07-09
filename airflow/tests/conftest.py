import datetime
import os
import pathlib
import subprocess
import sys

import pytest

from airflow.models import DagBag, DagRun
from airflow.models.connection import Connection
from airflow.settings import Session

sys.path.append(os.path.join(os.path.dirname(__file__), "../plugins"))


def pytest_sessionstart(session):
    subprocess.run(
        [
            "airflow",
            "db",
            "clean",
            "-y",
            "--clean-before-timestamp",
            str(datetime.datetime.now(datetime.timezone.utc)),
        ]
    )
    subprocess.run(["airflow", "db", "init"])


def get_most_recent_dag_run(dag_id: str):
    dag_runs = DagRun.find(dag_id=dag_id)
    dag_runs.sort(key=lambda x: x.execution_date, reverse=True)
    return dag_runs[0] if dag_runs else None


def get_dag(dag_bag: DagBag, file_name: str, dag_id: str):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    filepath = os.path.join(current_directory, "fixture_dags", file_name)
    dag_bag.process_file(filepath=filepath)
    assert dag_bag.import_errors == {}
    return dag_bag.get_dag(dag_id)


@pytest.fixture(scope="session")
def dag_bag() -> DagBag:
    current_directory = os.path.dirname(os.path.realpath(__file__))
    dag_folder = pathlib.Path(current_directory) / "fixture_dags"
    dag_bag = DagBag(include_examples=False, dag_folder=dag_folder, collect_dags=False)
    assert dag_bag.import_errors == {}
    return dag_bag


@pytest.fixture(scope="module")
def vcr_config():
    return {
        "filter_headers": [("cookie", "FILTERED"), ("Authorization", "FILTERED")],
        "allow_playback_repeats": True,
        "ignore_hosts": [
            "run-actions-1-azure-eastus.actions.githubusercontent.com",
            "run-actions-2-azure-eastus.actions.githubusercontent.com",
            "run-actions-3-azure-eastus.actions.githubusercontent.com",
            "sts.googleapis.com",
            "iamcredentials.googleapis.com",
            "oauth2.googleapis.com",
        ],
    }


def add_connection(session, **kwargs):
    session.add(Connection(**kwargs))
    session.commit()


def clean_connections(session, conn_id: str):
    existing_connections = (
        session.query(Connection).filter(Connection.conn_id == conn_id).all()
    )
    for connection in existing_connections:
        session.delete(connection)
    session.commit()


@pytest.fixture(scope="session", autouse=True)
def setup_module():
    session = Session()
    clean_connections(session, "kuba_default")
    add_connection(
        session,
        conn_id="kuba_default",
        conn_type="http",
        host=os.environ.get("KUBA_HOST"),
        login=os.environ.get("KUBA_LOGIN"),
        password=os.environ.get("KUBA_PASSWORD"),
        schema=os.environ.get("KUBA_SCHEMA"),
    )
    clean_connections(session, "airtable_default")
    add_connection(
        session,
        conn_id="airtable_default",
        conn_type="generic",
        password=os.environ.get("CALITP_AIRTABLE_PERSONAL_ACCESS_TOKEN"),
    )
    clean_connections(session, "http_ntd")
    add_connection(
        session,
        conn_id="http_ntd",
        conn_type="http",
        host="https://data.transportation.gov",
    )
    clean_connections(session, "http_blackcat")
    add_connection(
        session,
        conn_id="http_blackcat",
        conn_type="http",
        host="https://services.blackcattransit.com",
    )
    clean_connections(session, "http_mobility_database")
    add_connection(
        session,
        conn_id="http_mobility_database",
        conn_type="http",
        host="https://bit.ly/catalogs-csv",
    )
