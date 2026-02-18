# ---
# python_callable: close_expired_issues
# provide_context: true
# ---

import smtplib
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from pathlib import Path

import google.auth
import numpy as np
import pytz
from google.cloud import bigquery, secretmanager
from pyairtable import Api


def access_secret(project_id: str, secret_id: str, version: str = "latest") -> str:
    """Read a Secret Manager secret value as a string."""
    client = secretmanager.SecretManagerServiceClient()
    name = f"projects/{project_id}/secrets/{secret_id}/versions/{version}"
    resp = client.access_secret_version(request={"name": name})
    return resp.payload.data.decode("utf-8")


def send_email_smtp(to_emails, subject, html_content, sender_email, email_password):
    smtp_server = "smtp.gmail.com"
    smtp_port = 587

    msg = MIMEMultipart()
    msg["Subject"] = subject
    msg["From"] = sender_email

    if isinstance(to_emails, str):
        to_emails = [to_emails]
    msg["To"] = ", ".join(to_emails)
    msg.attach(MIMEText(html_content, "html"))

    with smtplib.SMTP(smtp_server, smtp_port) as server:
        server.starttls()
        server.login(sender_email, email_password)
        server.send_message(msg)


def close_expired_issues(**kwargs):
    # Detect project_id from ADC (staging vs prod)
    _, project_id = google.auth.default()

    # Secrets
    sender_email = access_secret(project_id, "F_SENDER_EMAIL")
    email_password = access_secret(project_id, "F_EMAIL_WORD")
    airtable_token = access_secret(project_id, "F_AIRTABLE_TOKEN")

    if not all([sender_email, email_password, airtable_token]):
        raise ValueError(
            f"Missing required secrets in Secret Manager for project_id={project_id}."
        )

    # Load SQL (same folder)
    dag_dir = Path(__file__).parent
    sql = (dag_dir / "query.sql").read_text()

    # Query BigQuery
    df = bigquery.Client(project=project_id).query(sql).to_dataframe()

    if df.empty:
        print("No expired issues to close.")
        return "No expired issues to close."

    # Status logic
    df["status"] = np.where(
        df["outreach_status"] == "Waiting on Customer Success",
        "Fixed - on its own",
        "Fixed - with Cal-ITP help",
    )
    today_pst = datetime.now(pytz.timezone("America/Los_Angeles")).date().isoformat()

    # Airtable
    base_id = "appmBGOFTvsDv4jdJ"
    table_name = "Transit Data Quality Issues"
    table = Api(airtable_token).table(base_id, table_name)

    updates = [
        {
            "id": row.issue_source_record_id,
            "fields": {
                "Status": row.status,
                "Outreach Status": None,
                "Resolution Date": today_pst,
            },
        }
        for row in df.itertuples(index=False)
    ]

    updated_records = []
    failed_batches = []
    BATCH_SIZE = 10

    for i in range(0, len(updates), BATCH_SIZE):
        batch = updates[i : i + BATCH_SIZE]  # noqa: E203
        batch_num = i // BATCH_SIZE + 1
        try:
            table.batch_update(batch)
            updated_records.extend(batch)
            print(f"✅ Updated batch {batch_num}")
        except Exception as e:
            print(f"❌ Failed batch {batch_num}: {e}")
            failed_batches.append((batch_num, str(e)))

    # Email summary
    updated_ids = [rec["id"] for rec in updated_records]
    updated_df = df[df["issue_source_record_id"].isin(updated_ids)]

    if not updated_df.empty:
        table_rows = ""
        for _, r in updated_df.iterrows():
            table_rows += (
                f"<tr><td>{r['issue_number']}</td>"
                f"<td>{r['gtfs_dataset_name']}</td>"
                f"<td>{r['status']}</td></tr>"
            )

        failed_html = (
            "<br>".join([f"Batch {b[0]}: {b[1]}" for b in failed_batches])
            if failed_batches
            else "None"
        )

        subject = "[Airflow] Airtable Issue Management - Close Expired Issues"
        body = f"""
        <b>✅ Successfully updated {len(updated_ids)} Airtable records.</b><br><br>
        <b>Closed Issues:</b><br>
        <table border="1" cellspacing="0" cellpadding="5">
            <tr>
                <th>Issue Number</th>
                <th>GTFS Dataset Name</th>
                <th>Status</th>
            </tr>
            {table_rows}
        </table><br><br>
        <b>❌ Failed batches:</b><br>
        {failed_html}
        """

        recipients = [
            "farhad.salemi@dot.ca.gov",
        ]

        try:
            send_email_smtp(recipients, subject, body, sender_email, email_password)
            print("📧 Email sent successfully via SMTP.")
        except Exception as e:
            print(f"⚠️ Email failed: {e}")
    else:
        print("ℹ️ No Airtable records were updated. Email not sent.")

    if not failed_batches:
        return f"Successfully closed {len(updated_records)} expired issues."
    return f"Closed {len(updated_records)} issues with failed batches: {failed_batches}"
