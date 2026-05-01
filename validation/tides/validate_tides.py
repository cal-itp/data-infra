"""Validate Cal-ITP TIDES tables against the official TIDES JSON schemas.

Exports a sample of one or more BigQuery TIDES tables to local parquet,
then runs Frictionless validation against the corresponding TIDES schema
file(s). Writes a human-readable report to stdout and to sample-report.txt.

Usage:
    python validate_tides.py --table fct_tides_vehicle_locations \
        --schema ~/projects/jarvus/tides/TIDES/spec/vehicle_locations.schema.json \
        --service-date 2026-04-30

Designed for local development against christopher_mart_gtfs / equivalent
sandbox dataset. For production validation against the public bucket exports,
point --table-uri at the GCS parquet path instead.
"""
import argparse
import json
import sys
from pathlib import Path

from google.cloud import bigquery
from frictionless import Resource, Schema, system, validate

# Allow validation of files at absolute paths. By default Frictionless 5.x
# rejects paths it considers "unsafe" (anything outside the working directory).
system.trusted = True


PROJECT_DEFAULT = "cal-itp-data-infra-staging"
LOCATION_DEFAULT = "us-west2"

# Columns that are not part of the TIDES schema and are dropped at export time.
# Match warehouse/models/mart/gtfs/fct_tides_vehicle_locations.sql.
INTERNAL_COLUMNS = {
    "dt",
    "base64_url",
    "gtfs_dataset_key",
    "organization_name",
    "organization_ntd_id",
}


def export_sample(client: bigquery.Client, dataset: str, table: str,
                  service_date: str, output_path: Path,
                  organization: str | None = None,
                  row_limit: int | None = None) -> int:
    """Export one service_date of a TIDES table to local parquet.

    Drops Cal-ITP internal columns to match what the public bucket export
    produces. Returns row count of the exported file.

    `organization` filters to a specific agency by name (substring match,
    case-insensitive) before dropping the internal columns. Useful for keeping
    sample exports small enough to fit in memory.
    `row_limit` caps the export at N rows after sorting by event/start time
    for determinism.
    """
    fq = f"`{client.project}.{dataset}.{table}`"
    org_predicate = (
        f"AND LOWER(organization_name) LIKE '%{organization.lower()}%'"
        if organization else ""
    )
    sort_col = "event_timestamp" if "vehicle_locations" in table else "actual_trip_start"
    limit_clause = f"\n    ORDER BY {sort_col}\n    LIMIT {row_limit}" if row_limit else ""
    sql = f"""
    SELECT * EXCEPT ({', '.join(sorted(INTERNAL_COLUMNS))})
    FROM {fq}
    WHERE service_date = DATE '{service_date}' {org_predicate}{limit_clause}
    """
    job = client.query(sql)
    df = job.to_dataframe()
    # Convert pandas float NaN to None on numeric columns so they serialize as
    # proper parquet nulls. Otherwise Frictionless reads them back as the
    # literal string 'nan' and fails minimum-constraint checks for any
    # nullable numeric TIDES field (odometer, speed, heading, etc.).
    import numpy as np
    for col in df.select_dtypes(include=['float', 'float64', 'float32']).columns:
        df[col] = df[col].astype(object).where(df[col].notna(), None)
    df.to_parquet(output_path, index=False)
    return len(df)


def load_tides_schema(schema_path: Path) -> Schema:
    """Load the TIDES JSON schema as a Frictionless Schema."""
    spec = json.loads(schema_path.read_text())
    # The TIDES JSON schemas are Frictionless-compatible Table Schema documents.
    return Schema.from_descriptor(spec)


def validate_table(parquet_path: Path, schema: Schema):
    """Run Frictionless validation of a parquet file against a TIDES schema."""
    resource = Resource(
        path=str(parquet_path),
        schema=schema,
        format="parquet",
    )
    return validate(resource)


def render_report(report, table_name: str, service_date: str, row_count: int) -> str:
    """Render a human-readable summary of the Frictionless report."""
    lines = []
    lines.append("=" * 70)
    lines.append(f"TIDES validation report: {table_name}")
    lines.append(f"Service date: {service_date}")
    lines.append(f"Exported rows: {row_count:,}")
    lines.append(f"Frictionless report valid: {report.valid}")
    lines.append("=" * 70)

    if not report.tasks:
        lines.append("No tasks recorded.")
        return "\n".join(lines)

    for task in report.tasks:
        lines.append(f"\nTask: {task.name}")
        lines.append(f"  Place: {task.place}")
        lines.append(f"  Stats: {task.stats}")
        lines.append(f"  Valid: {task.valid}")
        if task.errors:
            from collections import Counter
            field_counts = Counter()
            for err in task.errors:
                field = getattr(err, 'field_name', None) or '<unknown>'
                field_counts[(err.type, field)] += 1
            lines.append(f"  Errors ({len(task.errors)} total). By type+field:")
            for (etype, field), count in sorted(field_counts.items(), key=lambda x: -x[1]):
                lines.append(f"    {count:6d}  {etype:25s} field={field}")
            lines.append(f"\n  First 5 raw errors:")
            for err in task.errors[:5]:
                cell = getattr(err, 'cell', '')
                row_num = getattr(err, 'row_number', '?')
                field = getattr(err, 'field_name', '?')
                lines.append(f"    - row {row_num} field={field} cell={cell!r} type={err.type} note={err.note}")
        else:
            lines.append("  Errors: none")
        if task.warnings:
            lines.append(f"  Warnings ({len(task.warnings)}):")
            for w in task.warnings[:10]:
                lines.append(f"    - {w}")

    return "\n".join(lines)


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--project", default=PROJECT_DEFAULT)
    p.add_argument("--location", default=LOCATION_DEFAULT)
    p.add_argument("--dataset", required=True,
                   help="BQ dataset (e.g., christopher_mart_gtfs)")
    p.add_argument("--table", required=True,
                   help="BQ table (e.g., fct_tides_vehicle_locations)")
    p.add_argument("--schema", required=True, type=Path,
                   help="Path to TIDES JSON schema file")
    p.add_argument("--service-date", required=True,
                   help="Service date to export, YYYY-MM-DD")
    p.add_argument("--organization", default=None,
                   help="Filter to one agency by name substring (case-insensitive). "
                        "Useful for keeping sample exports manageable.")
    p.add_argument("--row-limit", type=int, default=None,
                   help="Cap the export at N rows. Default unlimited.")
    p.add_argument("--output-dir", type=Path,
                   default=Path(__file__).parent / "exports",
                   help="Where to write parquet + report")
    args = p.parse_args()

    args.output_dir.mkdir(parents=True, exist_ok=True)
    parquet_path = args.output_dir / f"{args.table}_{args.service_date}.parquet"
    report_path = args.output_dir.parent / "sample-report.txt"

    client = bigquery.Client(project=args.project, location=args.location)

    print(f"Exporting {args.dataset}.{args.table} for {args.service_date}"
          f"{f' (org=' + args.organization + ')' if args.organization else ''}"
          f"{f' (limit=' + str(args.row_limit) + ')' if args.row_limit else ''}...")
    row_count = export_sample(client, args.dataset, args.table,
                              args.service_date, parquet_path,
                              organization=args.organization,
                              row_limit=args.row_limit)
    print(f"Wrote {row_count:,} rows to {parquet_path}")

    print(f"Loading TIDES schema from {args.schema}...")
    schema = load_tides_schema(args.schema)

    print("Running Frictionless validation...")
    report = validate_table(parquet_path, schema)

    text = render_report(report, args.table, args.service_date, row_count)
    print(text)
    report_path.write_text(text + "\n")
    print(f"\nReport written to {report_path}")

    return 0 if report.valid else 1


if __name__ == "__main__":
    sys.exit(main())
