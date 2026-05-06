"""Validate Cal-ITP TIDES tables against the official TIDES JSON schemas.

Exports one feed's slice of a BigQuery TIDES table to local parquet, runs
Frictionless validation against the corresponding TIDES schema, and emits a
JSON Lines outcome record. The outcome envelope mirrors the shape produced by
`download_parse_and_validate_gtfs.py` so downstream consumers (BigQuery
external table, Metabase) can join TIDES validation results to the rest of the
GTFS pipeline outcomes.

Usage:

    uv run validate_tides.py \\
        --dataset christopher_mart_tides \\
        --table fct_tides_vehicle_locations \\
        --schema ~/projects/jarvus/tides/TIDES/spec/vehicle_locations.schema.json \\
        --service-date 2026-04-30 \\
        --gtfs-dataset-key 9edf45e373638700ca420b1e588efdaf \\
        --feed-name "Beach Cities Transit" \\
        --feed-url "https://feed.example/vehiclepositions" \\
        --outcome-output /tmp/test_outcome.jsonl

When the operator wraps this module, call `run_validation` directly to get
back the outcome dict; the CLI is for local sandbox runs.
"""

import argparse
import json
import sys
from base64 import urlsafe_b64encode
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

import pendulum
from frictionless import Resource, Schema, system, validate
from google.cloud import bigquery

system.trusted = True


PROJECT_DEFAULT = "cal-itp-data-infra-staging"
LOCATION_DEFAULT = "us-west2"

INTERNAL_COLUMNS = {
    "dt",
    "base64_url",
    "gtfs_dataset_key",
}

VEHICLE_LOCATIONS_TIME_COLUMN = "event_timestamp"
TRIPS_PERFORMED_TIME_COLUMN = "actual_trip_start"


def time_column_for(table: str) -> str:
    return (
        VEHICLE_LOCATIONS_TIME_COLUMN
        if "vehicle_locations" in table
        else TRIPS_PERFORMED_TIME_COLUMN
    )


def export_feed_parquet(
    client: bigquery.Client,
    dataset: str,
    table: str,
    service_date: str,
    gtfs_dataset_key: str,
    output_path: Path,
    row_limit: int | None = None,
) -> tuple[int, str | None, str | None]:
    """Export one (service_date, gtfs_dataset_key) slice of a TIDES table to
    local parquet. Returns row count, min event time, max event time."""
    fq = f"`{client.project}.{dataset}.{table}`"
    sort_col = time_column_for(table)
    limit_clause = (
        f"\n    ORDER BY {sort_col}\n    LIMIT {row_limit}" if row_limit else ""
    )
    sql = f"""
    SELECT * EXCEPT ({', '.join(sorted(INTERNAL_COLUMNS))})
    FROM {fq}
    WHERE service_date = DATE @service_date
      AND gtfs_dataset_key = @gtfs_dataset_key{limit_clause}
    """
    job_config = bigquery.QueryJobConfig(
        query_parameters=[
            bigquery.ScalarQueryParameter("service_date", "DATE", service_date),
            bigquery.ScalarQueryParameter(
                "gtfs_dataset_key", "STRING", gtfs_dataset_key
            ),
        ],
    )
    df = client.query(sql, job_config=job_config).to_dataframe()
    # Pandas float NaN serializes to parquet as the literal string 'nan' which
    # Frictionless reads as a non-null string, breaking minimum-constraint
    # checks on nullable numeric TIDES fields. Cast to object first.
    for col in df.select_dtypes(include=["float", "float64", "float32"]).columns:
        df[col] = df[col].astype(object).where(df[col].notna(), None)
    df.to_parquet(output_path, index=False)

    if len(df) and sort_col in df.columns:
        non_null = df[sort_col].dropna()
        first_event = (
            str(non_null.min().isoformat())
            if not non_null.empty and hasattr(non_null.min(), "isoformat")
            else (str(non_null.min()) if not non_null.empty else None)
        )
        last_event = (
            str(non_null.max().isoformat())
            if not non_null.empty and hasattr(non_null.max(), "isoformat")
            else (str(non_null.max()) if not non_null.empty else None)
        )
    else:
        first_event = None
        last_event = None

    return len(df), first_event, last_event


def load_tides_schema(schema_path: Path) -> Schema:
    spec = json.loads(schema_path.read_text())
    return Schema.from_descriptor(spec)


def run_frictionless(parquet_path: Path, schema: Schema):
    resource = Resource(
        path=str(parquet_path),
        schema=schema,
        format="parquet",
    )
    return validate(resource)


def base64_url(url: str) -> str:
    return urlsafe_b64encode(url.encode()).decode()


def feed_type_for(table: str) -> str:
    if "vehicle_locations" in table:
        return "tides_vehicle_locations"
    if "trips_performed" in table:
        return "tides_trips_performed"
    return f"tides_{table.replace('fct_tides_', '')}"


def summarize_errors(report) -> tuple[bool, dict, str | None]:
    """Reduce a Frictionless report into header counts plus an exception
    summary string. Returns (success, error_counts_by_type, exception)."""
    if not report.tasks:
        return report.valid, {}, (None if report.valid else "no tasks recorded")

    counts: Counter = Counter()
    for task in report.tasks:
        for err in task.errors:
            counts[err.type] += 1

    if report.valid:
        return True, dict(counts), None

    # Compose a terse exception summary capped at five distinct error types.
    top = counts.most_common(5)
    exception = "; ".join(f"{etype}={count}" for etype, count in top)
    remainder = len(counts) - len(top)
    if remainder:
        exception = "%s; +%d more" % (exception, remainder)
    return False, dict(counts), exception


def build_outcome(
    table: str,
    schema_path: Path,
    service_date: str,
    gtfs_dataset_key: str,
    feed_name: str,
    feed_url: str,
    ts: str,
    row_count: int,
    first_event: str | None,
    last_event: str | None,
    report,
    blob_path: str | None,
    process_stderr: str | None,
) -> dict:
    """Assemble the 8-field outcome envelope for a single (validate, feed)
    record. Mirrors the GTFS validator outcome shape so the records can land
    next to GTFS outcomes in the same external-table layout."""
    success, error_counts, exception = summarize_errors(report)

    config = {
        "extracted_at": ts,
        "name": feed_name,
        "url": feed_url,
        "feed_type": feed_type_for(table),
        "schedule_url_for_validation": None,
        "auth_query_params": {},
        "auth_headers": {},
        "computed": True,
        "tides_schema_url": str(schema_path),
        "service_date": service_date,
        "gtfs_dataset_key": gtfs_dataset_key,
        "warehouse_table": f"{table}",
    }

    extract = {
        "filename": base64_url(feed_url),
        "ts": ts,
        "config": config,
        "response_code": None,
        "response_headers": None,
    }

    header = {
        "row_count": row_count,
        "feed_count": 1 if row_count else 0,
        "first_event_timestamp": first_event,
        "last_event_timestamp": last_event,
        "frictionless_valid": report.valid,
        "error_counts_by_type": error_counts,
    }

    aggregation = {
        "filename": f"validate_{base64_url(feed_url)}.jsonl.gz",
        "step": "validate",
        "first_extract": extract,
    }

    return {
        "success": success,
        "exception": exception,
        "step": "validate",
        "extract": extract,
        "header": header,
        "aggregation": aggregation,
        "blob_path": blob_path,
        "process_stderr": process_stderr,
    }


def run_validation(
    *,
    project: str,
    location: str,
    dataset: str,
    table: str,
    schema_path: Path,
    service_date: str,
    gtfs_dataset_key: str,
    feed_name: str,
    feed_url: str,
    parquet_path: Path,
    ts: str | None = None,
    row_limit: int | None = None,
    blob_path: str | None = None,
    client: bigquery.Client | None = None,
) -> dict:
    """Run the full export-and-validate flow for one feed and return the
    outcome dict. Library entry point used by the Airflow operator.
    """
    client = client or bigquery.Client(project=project, location=location)
    ts = ts or datetime.now(timezone.utc).isoformat()

    row_count = 0
    first_event = None
    last_event = None
    report = None

    try:
        row_count, first_event, last_event = export_feed_parquet(
            client=client,
            dataset=dataset,
            table=table,
            service_date=service_date,
            gtfs_dataset_key=gtfs_dataset_key,
            output_path=parquet_path,
            row_limit=row_limit,
        )
        schema = load_tides_schema(schema_path)
        report = run_frictionless(parquet_path, schema)
    except Exception as exc:
        # Carry the failure on the outcome envelope rather than raising; the
        # downstream BigQuery external table is the monitoring surface.
        return _failed_outcome(
            table=table,
            schema_path=schema_path,
            service_date=service_date,
            gtfs_dataset_key=gtfs_dataset_key,
            feed_name=feed_name,
            feed_url=feed_url,
            ts=ts,
            row_count=row_count,
            blob_path=blob_path,
            process_stderr=repr(exc),
            exception=str(exc),
        )

    return build_outcome(
        table=table,
        schema_path=schema_path,
        service_date=service_date,
        gtfs_dataset_key=gtfs_dataset_key,
        feed_name=feed_name,
        feed_url=feed_url,
        ts=ts,
        row_count=row_count,
        first_event=first_event,
        last_event=last_event,
        report=report,
        blob_path=blob_path,
        process_stderr=None,
    )


def _failed_outcome(
    *,
    table: str,
    schema_path: Path,
    service_date: str,
    gtfs_dataset_key: str,
    feed_name: str,
    feed_url: str,
    ts: str,
    row_count: int,
    blob_path: str | None,
    process_stderr: str | None,
    exception: str,
) -> dict:
    config = {
        "extracted_at": ts,
        "name": feed_name,
        "url": feed_url,
        "feed_type": feed_type_for(table),
        "schedule_url_for_validation": None,
        "auth_query_params": {},
        "auth_headers": {},
        "computed": True,
        "tides_schema_url": str(schema_path),
        "service_date": service_date,
        "gtfs_dataset_key": gtfs_dataset_key,
        "warehouse_table": f"{table}",
    }
    extract = {
        "filename": base64_url(feed_url),
        "ts": ts,
        "config": config,
        "response_code": None,
        "response_headers": None,
    }
    aggregation = {
        "filename": f"validate_{base64_url(feed_url)}.jsonl.gz",
        "step": "validate",
        "first_extract": extract,
    }
    return {
        "success": False,
        "exception": exception,
        "step": "validate",
        "extract": extract,
        "header": {
            "row_count": row_count,
            "feed_count": 0,
            "first_event_timestamp": None,
            "last_event_timestamp": None,
            "frictionless_valid": False,
            "error_counts_by_type": {},
        },
        "aggregation": aggregation,
        "blob_path": blob_path,
        "process_stderr": process_stderr,
    }


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--project", default=PROJECT_DEFAULT)
    p.add_argument("--location", default=LOCATION_DEFAULT)
    p.add_argument(
        "--dataset", required=True, help="BQ dataset (e.g., christopher_mart_tides)"
    )
    p.add_argument(
        "--table", required=True, help="BQ table (e.g., fct_tides_vehicle_locations)"
    )
    p.add_argument(
        "--schema", required=True, type=Path, help="Path to TIDES JSON schema file"
    )
    p.add_argument(
        "--service-date", required=True, help="Service date to export, YYYY-MM-DD"
    )
    p.add_argument(
        "--gtfs-dataset-key",
        required=True,
        help="Feed key (e.g., 9edf45e373638700ca420b1e588efdaf)",
    )
    p.add_argument(
        "--feed-name",
        required=True,
        help="Human-readable agency or feed name (e.g., Beach Cities Transit)",
    )
    p.add_argument(
        "--feed-url",
        required=True,
        help="Source feed URL or warehouse table identifier; the base64 of "
        "this string is the join key in outcome filenames and partition paths",
    )
    p.add_argument(
        "--row-limit",
        type=int,
        default=None,
        help="Cap the export at N rows. Default unlimited.",
    )
    p.add_argument(
        "--output-dir",
        type=Path,
        default=Path(__file__).parent / "exports",
        help="Where to write the parquet sample",
    )
    p.add_argument(
        "--outcome-output",
        type=Path,
        default=None,
        help="Path to write the JSON Lines outcome record. Defaults to "
        "<output-dir>/validate_<base64-of-feed-url>.jsonl",
    )
    p.add_argument(
        "--blob-path",
        default=None,
        help="Optional gs:// path for the published artifact, recorded in "
        "the outcome envelope's blob_path field",
    )
    args = p.parse_args()

    args.output_dir.mkdir(parents=True, exist_ok=True)
    parquet_path = (
        args.output_dir
        / f"{args.table}_{args.service_date}_{args.gtfs_dataset_key}.parquet"
    )
    outcome_path = args.outcome_output or (
        args.output_dir / f"validate_{base64_url(args.feed_url)}.jsonl"
    )

    ts = pendulum.now("UTC").isoformat()

    print(
        f"Validating {args.dataset}.{args.table} feed={args.feed_name} "
        f"service_date={args.service_date}"
    )
    outcome = run_validation(
        project=args.project,
        location=args.location,
        dataset=args.dataset,
        table=args.table,
        schema_path=args.schema,
        service_date=args.service_date,
        gtfs_dataset_key=args.gtfs_dataset_key,
        feed_name=args.feed_name,
        feed_url=args.feed_url,
        parquet_path=parquet_path,
        ts=ts,
        row_limit=args.row_limit,
        blob_path=args.blob_path,
    )

    outcome_path.parent.mkdir(parents=True, exist_ok=True)
    with outcome_path.open("w") as fh:
        fh.write(json.dumps(outcome, separators=(",", ":")))
        fh.write("\n")

    print(f"Wrote outcome to {outcome_path}")
    print(
        f"success={outcome['success']} rows={outcome['header']['row_count']} "
        f"errors_by_type={outcome['header']['error_counts_by_type']}"
    )

    return 0 if outcome["success"] else 1


if __name__ == "__main__":
    sys.exit(main())
