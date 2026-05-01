import csv
import gzip
import io
import json
import os
import re
from typing import Sequence

from src.bigquery_cleaner import BigQueryCleaner

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.providers.google.cloud.hooks.gcs import GCSHook

ENGHOUSE_RAW_BUCKET = os.getenv("CALITP_BUCKET__ENGHOUSE_RAW")
ENGHOUSE_PARSED_BUCKET = os.getenv("CALITP_BUCKET__ENGHOUSE_PARSED")

# Semicolon-delimited files delivered by Enghouse via SFTP
# Raw path structure:  {entity}/{agency}/{filename}.csv
# Parsed path structure: {entity}/agency={agency}/dt={date}/{filename_stem}.jsonl.gz
ENTITIES = ["tap", "tx", "tr", "pw"]

_DATE_RE = re.compile(r"(\d{4}-\d{2}-\d{2})")


def _date_from_filename(filename: str, fallback: str) -> str:
    """Extract YYYY-MM-DD from a filename like taps-2026-04-15.csv.
    Falls back to the Airflow execution date string if no date is found."""
    m = _DATE_RE.search(filename)
    return m.group(1) if m else fallback


def _parse_csv(content: bytes) -> list:
    reader = csv.DictReader(
        io.StringIO(content.decode("utf-8-sig")),
        restkey="calitp_unknown_fields",
        delimiter=";",
    )
    fieldnames = [
        k for k in (reader.fieldnames or []) if k and k != "calitp_unknown_fields"
    ]
    return [
        {**row, "_line_number": line_number}
        for line_number, row in enumerate(reader, start=1)
        if not (
            fieldnames
            and all(row.get(k) in (k, None, "") for k in fieldnames)
            and any(row.get(k) == k for k in fieldnames)
        )
    ]


def _to_jsonl_gz(rows: list) -> bytes:
    cleaned = BigQueryCleaner(rows).clean()
    jsonl = "\n".join(json.dumps(row, separators=(",", ":")) for row in cleaned)
    return gzip.compress(jsonl.encode("utf-8"))


class EnghouseCSVToJSONLOperator(BaseOperator):
    """
    Converts Enghouse semicolon-delimited CSV files in the raw GCS bucket to
    JSONL.GZ in the parsed bucket. Runs over all entities and all agencies.

    Files already present in the parsed bucket are skipped, making this safe
    to re-run. To re-parse a specific file, delete it from the parsed bucket
    and re-trigger the DAG.

    Column names are normalised by BigQueryCleaner (lowercased, non-word
    characters replaced with underscores) so that the downstream BigQuery
    external tables and dbt models are insulated from casing changes in the
    source headers.
    """

    template_fields: Sequence[str] = ("gcp_conn_id",)

    def __init__(self, gcp_conn_id: str = "google_cloud_default", **kwargs) -> None:
        super().__init__(**kwargs)
        self.gcp_conn_id = gcp_conn_id
        self._gcs_hook = None

    def _hook(self) -> GCSHook:
        if self._gcs_hook is None:
            self._gcs_hook = GCSHook(gcp_conn_id=self.gcp_conn_id)
        return self._gcs_hook

    def _raw_bucket(self) -> str:
        assert ENGHOUSE_RAW_BUCKET, "CALITP_BUCKET__ENGHOUSE_RAW is not set"
        return ENGHOUSE_RAW_BUCKET.replace("gs://", "")

    def _parsed_bucket(self) -> str:
        assert ENGHOUSE_PARSED_BUCKET, "CALITP_BUCKET__ENGHOUSE_PARSED is not set"
        return ENGHOUSE_PARSED_BUCKET.replace("gs://", "")

    def execute(self, context: Context) -> dict:
        execution_date = context["ds"]  # YYYY-MM-DD
        stats = {"processed": 0, "skipped": 0, "errors": 0}

        for entity in ENTITIES:
            all_objects = (
                self._hook().list(
                    bucket_name=self._raw_bucket(),
                    prefix=f"{entity}/",
                )
                or []
            )

            csv_files = [p for p in all_objects if p.endswith(".csv")]
            self.log.info("Found %d CSV files under %s/", len(csv_files), entity)

            for path in csv_files:
                parts = path.split("/")
                if len(parts) != 3:
                    self.log.warning("Unexpected path structure, skipping: %s", path)
                    stats["errors"] += 1
                    continue

                _, agency, filename = parts
                date = _date_from_filename(filename, execution_date)
                stem = os.path.splitext(filename)[0]
                dest_path = f"{entity}/agency={agency}/dt={date}/{stem}.jsonl.gz"

                if self._hook().exists(
                    bucket_name=self._parsed_bucket(),
                    object_name=dest_path,
                ):
                    self.log.info("Already parsed, skipping: %s", dest_path)
                    stats["skipped"] += 1
                    continue

                self.log.info("Parsing %s -> %s", path, dest_path)
                try:
                    content = self._hook().download(
                        bucket_name=self._raw_bucket(),
                        object_name=path,
                    )
                    rows = _parse_csv(content)
                    data = _to_jsonl_gz(rows)
                    self._hook().upload(
                        bucket_name=self._parsed_bucket(),
                        object_name=dest_path,
                        data=data,
                        mime_type="application/octet-stream",
                        gzip=False,  # already gzip-compressed
                    )
                    self.log.info("Wrote %d rows to %s", len(rows), dest_path)
                    stats["processed"] += 1
                except Exception:
                    self.log.exception("Failed to parse %s", path)
                    stats["errors"] += 1

        self.log.info("Parse complete: %s", stats)
        if stats["errors"]:
            raise RuntimeError(
                f"Enghouse parse finished with {stats['errors']} error(s). "
                "See logs above for details."
            )
        return stats
