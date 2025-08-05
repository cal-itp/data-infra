# main.py
# This file contains the source code for your Google Cloud Function.

import os

# Import necessary libraries for SMTP email
import smtplib
from datetime import datetime
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from pathlib import Path

import functions_framework
import numpy as np

# import pandas as pd
import pytz
from google.cloud import bigquery
from pyairtable import Api


# --- Email Sending Function (using SMTPlib) ---
def send_email_smtp(to_emails, subject, html_content):
    """Sends an email using SMTPlib.

    Args:
        to_emails (list or str): A list of recipient email
        addresses or a single email string.
        subject (str): The subject line of the email.
        html_content (str): The HTML content of the email body.
    """
    sender_email = os.environ.get("F_SENDER_EMAIL")
    email_password = os.environ.get("F_EMAIL_WORD")

    if not sender_email or not email_password:
        raise ValueError(
            "Sender email or password environment variables not set for SMTP."
        )

    smtp_server = "smtp.gmail.com"
    smtp_port = 587  # Standard port for TLS

    # Create the email content
    msg = MIMEMultipart()
    msg["Subject"] = subject
    msg["From"] = sender_email

    if isinstance(to_emails, str):
        to_emails = [to_emails]
    msg["To"] = ", ".join(to_emails)

    msg.attach(MIMEText(html_content, "html"))

    # === Send the email ===
    try:
        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()  # Upgrade connection to secure TLS
            server.login(sender_email, email_password)
            server.send_message(msg)
            print("📧 Email sent successfully via SMTP.")
    except Exception as e:
        print(f"❌ Failed to send email via SMTP: {e}")
        raise  # Re-raise to ensure the function logs the failure


# --- Main Cloud Function Logic ---
@functions_framework.http
def update_expired_airtable_issues(request):
    """HTTP Cloud Function to update expired Airtable issues based on BigQuery data.

    This function queries BigQuery for issues, updates their status in Airtable,
    and logs the success/failure of batch updates. It also sends an email summary.
    """
    # Load query from a file named query.sql in the same directory as main.py
    try:
        sql_file_path = Path(os.path.dirname(os.path.abspath(__file__))) / "query.sql"
        sql = sql_file_path.read_text()
    except FileNotFoundError:
        error_msg = (
            "Error: query.sql not found. Please ensure it's deployed with main.py."
        )
        print(error_msg)
        return error_msg, 500
    except Exception as e:
        error_msg = f"Error reading query.sql: {e}"
        print(error_msg)
        return error_msg, 500

    try:
        client = bigquery.Client()
        df = client.query(sql).to_dataframe()
    except Exception as e:
        error_msg = f"Error querying BigQuery: {e}"
        print(error_msg)
        return error_msg, 500

    if df.empty:
        print("No records to update in Airtable.")
        return "No records to update in Airtable."

    # Apply status logic based on 'outreach_status'
    df["status"] = np.where(
        df["outreach_status"] == "Waiting on Customer Success",
        "Fixed - on its own",
        "Fixed - with Cal-ITP help",
    )

    # Get today's date in PST and format it for Airtable
    today_pst = datetime.now(pytz.timezone("America/Los_Angeles")).date().isoformat()

    # Retrieve Airtable API token from environment variables (via Secret Manager)
    airtable_token = os.environ.get("F_AIRTABLE_TOKEN")
    if not airtable_token:
        error_msg = "Error: F_AIRTABLE_TOKEN environment variable not set."
        print(error_msg)
        return error_msg, 500

    base_id = "appmBGOFTvsDv4jdJ"  # Airtable Base ID
    table_name = "Transit Data Quality Issues"  # Airtable Table Name

    try:
        api = Api(airtable_token)
        table = api.table(base_id, table_name)
    except Exception as e:
        error_msg = f"Error initializing Airtable API: {e}"
        print(error_msg)
        return error_msg, 500

    # Prepare batch updates for Airtable
    updates = [
        {
            "id": row.issue_source_record_id,
            "fields": {
                "Status": row.status,
                "Outreach Status": None,  # Set Outreach Status to None (clear it)
                "Resolution Date": today_pst,
            },
        }
        for row in df.itertuples(index=False)
    ]

    updated_records = []
    failed_batches = []

    BATCH_SIZE = 10  # Airtable API has limits; batching is good practice
    for i in range(0, len(updates), BATCH_SIZE):
        batch = updates[i : i + BATCH_SIZE]  # noqa: E203
        try:
            table.batch_update(batch)
            print(f"✅ Updated batch {i // BATCH_SIZE + 1}")
            updated_records.extend(batch)
        except Exception as e:
            print(f"❌ Failed batch {i // BATCH_SIZE + 1}: {e}")
            failed_batches.append((i // BATCH_SIZE + 1, str(e)))

    # --- Email Sending Logic (using the new send_email_smtp function) ---
    updated_ids = [rec["id"] for rec in updated_records]
    updated_datasets_df = df[df["issue_source_record_id"].isin(updated_ids)]

    # Only send email if there are any updated records
    if not updated_datasets_df.empty:
        table_rows = ""
        for _, row in updated_datasets_df.iterrows():
            issue_number = row["issue_number"]
            name = row["gtfs_dataset_name"]
            status = row["status"]
            table_rows += (
                f"<tr><td>{issue_number}</td><td>{name}</td><td>{status}</td></tr>"
            )

        recipients = [
            "farhad.salemi@dot.ca.gov",
            "evan.siroky@dot.ca.gov",
            "md.islam@dot.ca.gov",
        ]

        subject = "[Cloud Function] Airtable Update Summary"  # Changed subject prefix
        body = f"""
        <b>✅ Successfully updated {len(updated_ids)} records in Airtable.</b><br><br>

        <b>Resolved Issues:</b><br>
        <table border="1" cellspacing="0" cellpadding="5">
            <tr>
                <th>Issue Number</th>
                <th>GTFS Dataset Name</th>
                <th>Status</th>
           </tr>
            {table_rows}
        </table><br><br>

        <b>❌ Failed batches:</b><br>
        {
            '<br>'.join(
                f"Batch {b[0]}: {b[1]}"
                for b in failed_batches
            ) if failed_batches else 'None'
        }
        """

        try:
            send_email_smtp(to_emails=recipients, subject=subject, html_content=body)
            print("Email sent successfully!")
        except Exception as e:
            print(f"⚠️ Email failed: {e}")
            # Decide if you want the function to fail or continue if email fails
            # For now, it will print the error but still return success for the main job
    else:
        print("ℹ️ No Airtable records were updated. Email not sent.")

    # Return a final status for the HTTP trigger
    if not failed_batches:
        return f"Successfully updated {len(updated_records)} records in Airtable.", 200
    else:
        return (
            f"Updated {len(updated_records)} records, but encountered failures "
            f"in {len(failed_batches)} batches. "
            f"Failed batches: {failed_batches}",
            200,
        )
