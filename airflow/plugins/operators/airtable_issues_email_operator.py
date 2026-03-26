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
    )

    def __init__(
        self,
        to_emails: list[str] | str,
        update_result: dict[str, Any],
        subject: str = "[Airflow] Airtable Issue Management",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self.to_emails = to_emails
        self.subject = subject
        self.update_result = update_result

    def build_table_rows(self, email_rows: list[dict[str, Any]]) -> str:
        table_rows = ""

        for row in email_rows:
            table_rows += (
                f"<tr><td>{row.get('issue_number', '')}</td>"
                f"<td>{row.get('gtfs_dataset_name', '')}</td>"
                f"<td>{row.get('status', '')}</td>"
                f"<td>{row.get('new_end_date', '')}</td></tr>"
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
        email_rows: list[dict[str, Any]],
        failed_batches: list[dict[str, Any]],
    ) -> str:
        table_rows = self.build_table_rows(email_rows)
        failed_html = self.build_failed_html(failed_batches)

        return f"""
        <b>✅ Successfully updated {len(email_rows)} Airtable records.</b><br><br>
        <b>Closed About to Expire Issues:</b><br>
        <table border="1" cellspacing="0" cellpadding="5">
            <tr>
                <th>Issue Number</th>
                <th>GTFS Dataset Name</th>
                <th>Status</th>
                <th>New End Date</th>
            </tr>
            {table_rows}
        </table><br><br>
        <b>❌ Failed batches:</b><br>
        {failed_html}
        """

    def execute(self, context: Context) -> dict[str, Any]:
        del context

        update_result = self.update_result

        if not update_result:
            self.log.info("No update result found. Email not sent.")
            return {
                "email_sent": False,
                "reason": "no_update_result",
            }

        email_rows = update_result.get("email_rows", [])
        failed_batches = update_result.get("failed_batches", [])
        updated_record_ids = update_result.get("updated_record_ids", [])

        if not email_rows:
            self.log.info("No updated rows. Email not sent.")
            return {
                "email_sent": False,
                "reason": "no_updated_rows",
            }

        body = self.build_email_body(email_rows, failed_batches)

        send_email(
            to=self.to_emails,
            subject=self.subject,
            html_content=body,
        )

        self.log.info("Email sent via Airflow send_email.")

        return {
            "email_sent": True,
            "updated_count": len(email_rows),
            "updated_record_ids": updated_record_ids,
            "failed_batches": failed_batches,
        }
