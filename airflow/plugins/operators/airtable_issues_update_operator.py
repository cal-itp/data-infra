from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Sequence

from hooks.airtable_issues_hook import AirtableIssuesHook

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context


class AirtableIssuesUpdateOperator(BaseOperator):
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

    def derive_status(self, outreach_status: str | None) -> str:
        if outreach_status == "Waiting on Customer Success":
            return "Fixed - on its own"
        return "Fixed - with Cal-ITP help"

    def build_updates(self, rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
        resolution_date = self.today()

        return [
            {
                "id": row["issue_source_record_id"],
                "fields": {
                    "Status": self.derive_status(row.get("outreach_status")),
                    "Outreach Status": None,
                    "Resolution Date": resolution_date,
                },
            }
            for row in rows
        ]

    def build_email_rows(self, rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
        email_rows = []

        for row in rows:
            issue_type_name = row.get("issue_type_name")
            email_row = {
                "issue_number": row.get("issue_number"),
                "issue_type_name": issue_type_name,
                "gtfs_dataset_name": row.get("gtfs_dataset_name"),
                "status": self.derive_status(row.get("outreach_status")),
                "new_end_date": "NA",
                "rt_completeness_percentage": "NA",
                "service_name": row.get("service_name"),
            }

            if issue_type_name == "GTFS Realtime Completeness Problem":
                email_row["rt_completeness_percentage"] = row.get(
                    "rt_completeness_percentage"
                )
            else:
                email_row["new_end_date"] = row.get("new_end_date")

            email_rows.append(email_row)

        return email_rows

    def execute(self, context: Context) -> dict[str, Any]:
        del context

        rows = self.rows

        if not rows:
            self.log.info("No Airtable issue rows found.")
            return {
                "updated_count": 0,
                "updated_record_ids": [],
                "failed_batches": [],
                "email_rows": [],
            }

        updates = self.build_updates(rows)

        updated_records: list[dict[str, Any]] = []
        email_rows: list[dict[str, Any]] = []
        failed_batches: list[dict[str, Any]] = []

        for i in range(0, len(updates), self.batch_size):
            start = i
            end = i + self.batch_size
            batch = updates[start:end]
            batch_rows = rows[start:end]

            batch_num = i // self.batch_size + 1

            try:
                self.airtable_hook().batch_update(
                    air_base_id=self.air_base_id,
                    air_table_name=self.air_table_name,
                    records=batch,
                )
                updated_records.extend(batch)
                email_rows.extend(self.build_email_rows(batch_rows))
                self.log.info("Updated Airtable batch %s successfully.", batch_num)

            except Exception as exc:
                self.log.exception("Failed Airtable batch %s", batch_num)
                failed_batches.append(
                    {
                        "batch_num": batch_num,
                        "error": str(exc),
                        "record_ids": [record["id"] for record in batch],
                    }
                )

        return {
            "updated_count": len(updated_records),
            "updated_record_ids": [record["id"] for record in updated_records],
            "failed_batches": failed_batches,
            "email_rows": email_rows,
        }
