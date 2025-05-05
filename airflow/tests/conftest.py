import datetime
import os
import pathlib
import pytest
import subprocess
import sys

from airflow.settings import Session
from airflow.models import DagBag, DagRun
from airflow.models.connection import Connection

sys.path.append(os.path.join(os.path.dirname(__file__), "../plugins"))

def pytest_sessionstart(session):
    subprocess.run(["airflow", "db", "clean", "-y", "--clean-before-timestamp", str(datetime.datetime.now(datetime.timezone.utc))])
    subprocess.run(["airflow", "db", "init"])

def get_most_recent_dag_run(dag_id: str):
    dag_runs = DagRun.find(dag_id=dag_id)
    dag_runs.sort(key=lambda x: x.execution_date, reverse=True)
    return dag_runs[0] if dag_runs else None

def get_dag(dag_bag: DagBag, file_name: str, dag_id: str):
    current_directory = os.path.dirname(os.path.realpath(__file__))
    dag_folder = pathlib.Path(current_directory) / '..' / 'dags'
    filepath = dag_folder / file_name
    dag_bag.process_file(filepath=str(filepath.resolve()))
    assert dag_bag.import_errors == {}
    return dag_bag.get_dag(dag_id)

@pytest.fixture(scope="session")
def dag_bag() -> DagBag:
    current_directory = os.path.dirname(os.path.realpath(__file__))
    dag_folder = pathlib.Path(current_directory) / '..' / '..' / 'dags'
    dag_bag = DagBag(include_examples=False, dag_folder=dag_folder, collect_dags=False)
    assert dag_bag.import_errors == {}
    return dag_bag

@pytest.fixture(scope="module")
def vcr_config():
    return {
        "filter_headers": [("cookie", "FILTERED")],
    }

@pytest.fixture(scope="session", autouse=True)
def setup_module():
    session = Session()
    clean_connections(session)

    kuba_default = Connection(
        conn_id="kuba_default",
        conn_type="http",
        host=os.environ.get("KUBA_HOST"),
        login=os.environ.get("KUBA_LOGIN"),
        password=os.environ.get("KUBA_PASSWORD"),
        schema=os.environ.get("KUBA_SCHEMA")
    )
    session.add(kuba_default)
    session.commit()

def clean_connections(session):
    existing_connections = (
        session.query(Connection).filter(Connection.conn_id == "kuba_default").all()
    )
    for connection in existing_connections:
        session.delete(connection)
    session.commit()
