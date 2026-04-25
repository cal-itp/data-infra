from __future__ import annotations

import os
from typing import Any, Sequence

from airflow.models import BaseOperator
from airflow.models.taskinstance import Context
from airflow.utils.email import send_email


class AirtableIssuesEmailOperator(BaseOperator):
    template_fields: Sequence[str] = (
        "to_emails",
        "subject",
        "expiring_update_result",
        "expiring_create_result",
        "rt_update_result",
    )

    def __init__(
        self,
        to_emails: list[str] | str,
        expiring_update_result: dict[str, Any],
        expiring_create_result: dict[str, Any],
        rt_update_result: dict[str, Any],
        subject: str = "[Airflow] Airtable Issue Management",
        **kwargs,
    ) -> None:
        super().__init__(**kwargs)

        self.to_emails = to_emails
        self.subject = subject
        self.expiring_update_result = expiring_update_result
        self.expiring_create_result = expiring_create_result
        self.rt_update_result = rt_update_result

    def build_closed_table_rows(self, email_rows: list[dict[str, Any]]) -> str:
        table_rows = ""

        for row in email_rows:
            rt = row.get("rt_completeness_percentage")
            rt_display = f"{rt}%" if rt != "NA" else rt
            table_rows += (
                f"<tr><td>{row.get('issue_number', '')}</td>"
                f"<td>{row.get('issue_type_name', '')}</td>"
                f"<td>{row.get('gtfs_dataset_name', '')}</td>"
                f"<td>{row.get('service_name', '')}</td>"
                f"<td>{row.get('status', '')}</td>"
                f"<td>{row.get('new_end_date', '')}</td>"
                f"<td>{rt_display}</td></tr>"
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
        return "<br>".join(
            [
                f"Batch {batch['batch_num']}: {batch['error']}"
                for batch in failed_batches
            ]
        )

    def get_issue_type(self, expiration_status: str) -> str:
        if expiration_status == "Expired":
            return "Expired Schedule Feed"
        return "About to Expire Schedule Feed"

    def is_mtc_511_agency(self, gtfs_dataset_name: str) -> str:
        return "Yes" if gtfs_dataset_name.startswith("Bay Area 511") else "No"

    def build_ticket_description(
        self, expiration_status: str, max_end_date: str
    ) -> str:
        return f"The feed is {expiration_status} on {max_end_date}"

    def build_individual_create_email_subject(self, row: dict[str, Any]) -> str:
        return (
            f"{row.get('gtfs_dataset_name', '')} - {row.get('expiration_status', '')}"
        )

    def build_individual_create_email_body(self, row: dict[str, Any]) -> str:
        gtfs_dataset_name = row.get("gtfs_dataset_name", "")
        expiration_status = row.get("expiration_status", "")
        max_end_date = row.get("max_end_date", "")
        organization_name = row.get("organization_name", "")

        ticket_description = self.build_ticket_description(
            expiration_status=expiration_status,
            max_end_date=max_end_date,
        )
        issue_type = self.get_issue_type(expiration_status)
        is_mtc_511 = self.is_mtc_511_agency(gtfs_dataset_name)

        return f"""
        <table>
            <tr><td><b>Ticket description:</b></td><td>{ticket_description}</td></tr>
            <tr><td><b>Issue Type:</b></td><td>{issue_type}</td></tr>
            <tr><td><b>Is this an MTC 511 agency?</b></td><td>{is_mtc_511}</td></tr>
            <tr><td><b>Companies Associated records:</b></td><td>{organization_name}</td></tr>
            <tr><td><b>Internal Support Ticket Subject:</b></td><td>GTFS Data Quality</td></tr>
        </table>
        """

    def send_individual_create_emails(
        self, created_email_rows: list[dict[str, Any]]
    ) -> None:
        recipient = os.getenv("HUBSPOT_NOTIFICATION_EMAIL")

        for row in created_email_rows:
            subject = self.build_individual_create_email_subject(row)
            body = self.build_individual_create_email_body(row)

            send_email(
                to=recipient,
                subject=subject,
                html_content=body,
            )

            self.log.info(
                "Sent individual create email for gtfs_dataset_name=%s",
                row.get("gtfs_dataset_name", ""),
            )

    def build_email_body(
        self,
        closed_email_rows: list[dict[str, Any]],
        closed_failed_batches: list[dict[str, Any]],
        created_email_rows: list[dict[str, Any]],
        created_failed_batches: list[dict[str, Any]],
    ) -> str:
        sections = []

        if created_email_rows:
            created_table_rows = self.build_created_table_rows(created_email_rows)

            sections.append(
                f"""
                <b>Successfully created {len(created_email_rows)} About to Expire Issues in Airtable and HubSpot.</b><br>
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

                """
            )

        if created_failed_batches:
            sections.append(
                f"""
                <b>❌ Failed create batches:</b><br>
                {self.build_failed_html(created_failed_batches)}
                """
            )

        if closed_email_rows:
            closed_table_rows = self.build_closed_table_rows(closed_email_rows)

            sections.append(
                f"""
                <b>Successfully closed {len(closed_email_rows)} Airtable records.</b><br>
                <table border="1" cellspacing="0" cellpadding="5">
                    <tr>
                        <th>Issue</th>
                        <th>Issue Type</th>
                        <th>GTFS Dataset Name</th>
                        <th>Service Name</th>
                        <th>Status</th>
                        <th>End Date</th>
                        <th>RT Completeness</th>
                    </tr>
                    {closed_table_rows}
                </table>
                """
            )

        if closed_failed_batches:
            sections.append(
                f"""
                <b>❌ Failed update batches:</b><br>
                {self.build_failed_html(closed_failed_batches)}
                """
            )

        return "<br><br>".join(sections)

    def execute(self, context: Context) -> dict[str, Any]:
        del context

        expiring_update_result = self.expiring_update_result or {}
        rt_update_result = self.rt_update_result or {}
        create_result = self.expiring_create_result or {}

        closed_email_rows = expiring_update_result.get(
            "email_rows", []
        ) + rt_update_result.get("email_rows", [])

        closed_failed_batches = expiring_update_result.get(
            "failed_batches", []
        ) + rt_update_result.get("failed_batches", [])

        updated_record_ids = expiring_update_result.get(
            "updated_record_ids", []
        ) + rt_update_result.get("updated_record_ids", [])

        created_email_rows = create_result.get("email_rows", [])
        created_failed_batches = create_result.get("failed_batches", [])
        created_record_ids = create_result.get("created_record_ids", [])

        if (
            not closed_email_rows
            and not created_email_rows
            and not closed_failed_batches
            and not created_failed_batches
        ):
            self.log.info("No updated or created rows. Email not sent.")
            return {
                "email_sent": False,
                "reason": "no_updated_or_created_rows",
            }

        if created_email_rows:
            self.send_individual_create_emails(created_email_rows)

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

        self.log.info("Mass summary email sent via Airflow send_email.")

        return {
            "email_sent": True,
            "updated_count": len(closed_email_rows),
            "created_count": len(created_email_rows),
            "updated_record_ids": updated_record_ids,
            "created_record_ids": created_record_ids,
            "failed_update_batches": closed_failed_batches,
            "failed_create_batches": created_failed_batches,
        }
