import datetime
import os
import subprocess
import sys

sys.path.append(os.path.join(os.path.dirname(__file__), "../plugins"))

def pytest_sessionstart(session):
    subprocess.run(["airflow", "db", "clean", "-y", "--clean-before-timestamp", str(datetime.datetime.now(datetime.timezone.utc))])
    subprocess.run(["airflow", "db", "init"])
