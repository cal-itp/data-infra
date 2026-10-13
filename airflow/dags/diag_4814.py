# TEMPORARY cleanup for cal-itp/data-infra#4814 -- delete before PR
import os
from datetime import datetime
from pathlib import Path

from airflow import DAG

_dags_dir = Path(__file__).parent
_TARGETS = (
    "download_gtfs_schedule_v2",
    "unzip_and_validate_gtfs_schedule_hourly",
)


def _remove_empty_dirs() -> str:
    results = []
    for name in _TARGETS:
        root = _dags_dir / name
        if not root.is_dir():
            results.append(f"{name}: not present")
            continue
        # Bottom-up so children go before parents. os.rmdir refuses to
        # remove a non-empty directory and never touches files.
        for dirpath, _dirnames, _filenames in os.walk(root, topdown=False):
            rel = Path(dirpath).relative_to(_dags_dir)
            try:
                os.rmdir(dirpath)
                results.append(f"removed {rel}")
            except OSError as e:
                results.append(f"kept {rel}: {e!r}")
    return " | ".join(results)


_result = _remove_empty_dirs()
_still_there = [n for n in _TARGETS if (_dags_dir / n).exists()]

with DAG(
    dag_id="diag_4814",
    description=f"{_result} | still_there={_still_there}",
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["temporary", "diag_4814"],
):
    pass
