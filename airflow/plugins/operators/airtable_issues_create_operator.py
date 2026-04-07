from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Sequence

from hooks.airtable_issues_hook import AirtableIssuesHook

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context

ISSUE_TYPE_MAP = {
    "Expired": "recXHbaInR8Uebp5D",
    "Expiring in Less Than 30 Days": "recEmZkgNkfKgYe6N",
}


class AirtableIssuesCreateOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "air_base_id",
        "air_table_name",
        "airtable_conn_id",
        "rows",
    )

    def __init__(
        self,
        air_base_id: str,
        air_table_name: str,
        rows: list[dict[str, Any]],
        airtable_conn_id: str = "airtable_issue_management",
        batch_size: int = 10,
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self.air_base_id = air_base_id
        self.air_table_name = air_table_name
        self.rows = rows
        self.airtable_conn_id = airtable_conn_id
        self.batch_size = batch_size

    def airtable_hook(self) -> AirtableIssuesHook:
        return AirtableIssuesHook(airtable_conn_id=self.airtable_conn_id)

    def today(self) -> str:
        return datetime.now(timezone.utc).date().isoformat()

    def build_creates(self, rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
        today_date = self.today()

        return [
            {
                "Issue Type": [ISSUE_TYPE_MAP[row["expiration_status"]]],
                "GTFS Datasets": [row["gtfs_dataset_record_id"]],
                "Status": "Outreach",
                "Outreach Status": "Waiting on Customer Success",
                "Description": (
                    f"The feed expired on {row['max_end_date']}."
                    if row["expiration_status"] == "Expired"
                    else f"The feed is about to expire on {row['max_end_date']}."
                ),
                "Services": [row["service_record_id"]],
                "Waiting Since": today_date,
            }
            for row in rows
        ]

    def build_email_rows(
        self,
        rows: list[dict[str, Any]],
        created_records: list[dict[str, Any]],
    ) -> list[dict[str, Any]]:
        email_rows = []

        for source_row, created_record in zip(rows, created_records):
            fields = created_record.get("fields", {})

            email_rows.append(
                {
                    "issue_number": fields.get("Issue #"),
                    "gtfs_dataset_name": source_row["gtfs_dataset_name"],
                    "service_name": source_row["service_name"],
                    "expiration_status": source_row["expiration_status"],
                    "max_end_date": str(source_row["max_end_date"]),
                    "organization_name": source_row["organization_name"],
                }
            )

        return email_rows

    def execute(self, context: Context) -> dict[str, Any]:
        del context

        rows = self.rows

        if not rows:
            self.log.info("No Airtable issue rows found.")
            return {
                "created_count": 0,
                "created_record_ids": [],
                "failed_batches": [],
                "email_rows": [],
            }

        creates = self.build_creates(rows)

        created_records: list[dict[str, Any]] = []
        email_rows: list[dict[str, Any]] = []
        failed_batches: list[dict[str, Any]] = []

        for i in range(0, len(creates), self.batch_size):
            start = i
            end = i + self.batch_size
            batch = creates[start:end]
            batch_rows = rows[start:end]

            batch_num = i // self.batch_size + 1

            try:
                batch_created_records = self.airtable_hook().batch_create(
                    air_base_id=self.air_base_id,
                    air_table_name=self.air_table_name,
                    records=batch,
                )
                created_records.extend(batch_created_records)
                email_rows.extend(
                    self.build_email_rows(batch_rows, batch_created_records)
                )
                self.log.info("Created Airtable batch %s successfully.", batch_num)

            except Exception as exc:
                self.log.exception("Failed Airtable batch %s", batch_num)
                failed_batches.append(
                    {
                        "batch_num": batch_num,
                        "error": str(exc),
                        "row_identifiers": [
                            {
                                "gtfs_dataset_record_id": row["gtfs_dataset_record_id"],
                                "service_record_id": row["service_record_id"],
                            }
                            for row in batch_rows
                        ],
                    }
                )

        return {
            "created_count": len(created_records),
            "created_record_ids": [record["id"] for record in created_records],
            "failed_batches": failed_batches,
            "email_rows": email_rows,
        }
