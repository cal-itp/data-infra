# TEMPORARY DIAGNOSTIC for cal-itp/data-infra#4814 -- delete before PR
from datetime import datetime
from pathlib import Path

from airflow import DAG

_dags_dir = Path(__file__).parent


def _describe() -> str:
    try:
        top = sorted(
            f"{p.name}{'/' if p.is_dir() else ''}" for p in _dags_dir.iterdir()
        )
        parts = [f"dir={_dags_dir}", f"top={top}"]
        for name in (
            "download_gtfs_schedule_v2",
            "unzip_and_validate_gtfs_schedule_hourly",
        ):
            d = _dags_dir / name
            contents = (
                sorted(str(p.relative_to(d)) for p in d.rglob("*"))
                if d.is_dir()
                else None
            )
            parts.append(f"{name}: exists={d.exists()} contents={contents}")
        return " | ".join(parts)
    except Exception as e:  # noqa: BLE001
        return f"diag failed: {e!r}"


with DAG(
    dag_id="diag_4814",
    description=_describe(),
    start_date=datetime(2024, 1, 1),
    schedule=None,
    catchup=False,
    tags=["temporary", "diag_4814"],
):
    pass
