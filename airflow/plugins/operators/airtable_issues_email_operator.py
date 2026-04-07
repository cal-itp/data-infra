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
        <b>Ticket description:</b> {ticket_description}<br><br>
        <b>Issue Type:</b> {issue_type}<br><br>
        <b>Is this an MTC 511 agency?</b> {is_mtc_511}<br><br>
        <b>Companies Associated records:</b> {organization_name}<br><br>
        <b>Internal Support Ticket Subject:</b> GTFS Data Quality
        """

    def send_individual_create_emails(
        self, created_email_rows: list[dict[str, Any]]
    ) -> None:
        recipient = "tdq@calitp.org"

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
        individual_create_emails_sent: bool = False,
    ) -> str:
        closed_table_rows = self.build_closed_table_rows(closed_email_rows)
        created_table_rows = self.build_created_table_rows(created_email_rows)

        closed_failed_html = self.build_failed_html(closed_failed_batches)
        created_failed_html = self.build_failed_html(created_failed_batches)

        # ✅ Polished HubSpot section
        hubspot_section = ""
        if individual_create_emails_sent:
            hubspot_section = """
            <b>✅ HubSpot Ticket Creation</b><br><br>
            Corresponding tickets were submitted in HubSpot.<br><br>
            """

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

        {hubspot_section}

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

        individual_create_emails_sent = False

        if created_email_rows:
            self.send_individual_create_emails(created_email_rows)
            individual_create_emails_sent = True

        body = self.build_email_body(
            closed_email_rows=closed_email_rows,
            closed_failed_batches=closed_failed_batches,
            created_email_rows=created_email_rows,
            created_failed_batches=created_failed_batches,
            individual_create_emails_sent=individual_create_emails_sent,
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
