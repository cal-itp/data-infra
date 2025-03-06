import subprocess
import datetime


def pytest_sessionstart(session):
    subprocess.run(["airflow", "db", "init"])

def pytest_sessionfinish(session):
    subprocess.run(["airflow", "db", "clean", "-y", "--clean-before-timestamp", str(datetime.datetime.today())])
