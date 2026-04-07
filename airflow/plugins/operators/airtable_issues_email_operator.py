from __future__ import annotations

from typing import Any, Sequence

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.utils.email import send_email


class AirtableIssuesEmailOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "to_emails",
        "subject",
        "update_result",
        "create_result",
    )

    def __init__(
        self,
        to_emails: list[str] | str,
        update_result: dict[str, Any],
        create_result: dict[str, Any],
        subject: str = "[Airflow] Airtable Issue Management",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self.to_emails = to_emails
        self.subject = subject
        self.update_result = update_result
        self.create_result = create_result

    def build_closed_table_rows(self, email_rows: list[dict[str, Any]]) -> str:
        table_rows = ""

        for row in email_rows:
            table_rows += (
                f"<tr><td>{row.get('issue_number', '')}</td>"
                f"<td>{row.get('gtfs_dataset_name', '')}</td>"
                f"<td>{row.get('service_name', '')}</td>"
                f"<td>{row.get('status', '')}</td>"
                f"<td>{row.get('new_end_date', '')}</td></tr>"
            )

        return table_rows

    def build_created_table_rows(self, email_rows: list[dict[str, Any]]) -> str:
        table_rows = ""

        for row in email_rows:
            table_rows += (
                f"<tr><td>{row.get('issue_number', '')}</td>"
                f"<td>{row.get('gtfs_dataset_name', '')}</td>"
                f"<td>{row.get('service_name', '')}</td>"
                f"<td>{row.get('expiration_status', '')}</td>"
                f"<td>{row.get('max_end_date', '')}</td></tr>"
            )

        return table_rows

    def build_failed_html(self, failed_batches: list[dict[str, Any]]) -> str:
        if not failed_batches:
            return "None"

        return "<br>".join(
            [
                f"Batch {batch['batch_num']}: {batch['error']}"
                for batch in failed_batches
            ]
        )

    def build_email_body(
        self,
        closed_email_rows: list[dict[str, Any]],
        closed_failed_batches: list[dict[str, Any]],
        created_email_rows: list[dict[str, Any]],
        created_failed_batches: list[dict[str, Any]],
    ) -> str:
        closed_table_rows = self.build_closed_table_rows(closed_email_rows)
        created_table_rows = self.build_created_table_rows(created_email_rows)

        closed_failed_html = self.build_failed_html(closed_failed_batches)
        created_failed_html = self.build_failed_html(created_failed_batches)

        return f"""
        <b>✅ Successfully updated {len(closed_email_rows)} Airtable records.</b><br><br>
        <b>Closed the following About to Expire Issues:</b><br>
        <table border="1" cellspacing="0" cellpadding="5">
            <tr>
                <th>Issue Number</th>
                <th>GTFS Dataset Name</th>
                <th>Service Name</th>
                <th>Status</th>
                <th>New End Date</th>
            </tr>
            {closed_table_rows}
        </table><br><br>

        <b>❌ Failed update batches:</b><br>
        {closed_failed_html}<br><br>

        <b>✅ Successfully created {len(created_email_rows)} Airtable records.</b><br><br>
        <b>Created the following About to Expire Issues:</b><br>
        <table border="1" cellspacing="0" cellpadding="5">
            <tr>
                <th>Issue Number</th>
                <th>GTFS Dataset Name</th>
                <th>Service Name</th>
                <th>Expiration Status</th>
                <th>Max End Date</th>
            </tr>
            {created_table_rows}
        </table><br><br>

        <b>❌ Failed create batches:</b><br>
        {created_failed_html}
        """

    def execute(self, context: Context) -> dict[str, Any]:
        del context

        update_result = self.update_result or {}
        create_result = self.create_result or {}

        closed_email_rows = update_result.get("email_rows", [])
        closed_failed_batches = update_result.get("failed_batches", [])
        updated_record_ids = update_result.get("updated_record_ids", [])

        created_email_rows = create_result.get("email_rows", [])
        created_failed_batches = create_result.get("failed_batches", [])
        created_record_ids = create_result.get("created_record_ids", [])

        if not closed_email_rows and not created_email_rows:
            self.log.info("No updated or created rows. Email not sent.")
            return {
                "email_sent": False,
                "reason": "no_updated_or_created_rows",
            }

        body = self.build_email_body(
            closed_email_rows=closed_email_rows,
            closed_failed_batches=closed_failed_batches,
            created_email_rows=created_email_rows,
            created_failed_batches=created_failed_batches,
        )

        send_email(
            to=self.to_emails,
            subject=self.subject,
            html_content=body,
        )

        self.log.info("Email sent via Airflow send_email.")

        return {
            "email_sent": True,
            "updated_count": len(closed_email_rows),
            "created_count": len(created_email_rows),
            "updated_record_ids": updated_record_ids,
            "created_record_ids": created_record_ids,
            "failed_update_batches": closed_failed_batches,
            "failed_create_batches": created_failed_batches,
        }
