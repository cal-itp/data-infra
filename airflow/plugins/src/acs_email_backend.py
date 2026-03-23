from airflow.configuration import conf
from airflow.hooks.base import BaseHook
from azure.communication.email import EmailClient

def send_email(
    to,
    subject,
    html_content,
    files=None,
    cc=None,
    bcc=None,
    mime_subtype="mixed",
    mime_charset="utf-8",
    **kwargs,
):
    conn = BaseHook.get_connection("azure_acs_default")
    connection_string = conn.password
    client = EmailClient.from_connection_string(connection_string)

    if isinstance(to, str):
        to = [to]

    recipients = {"to": [{"address": addr} for addr in to]}
    sender_address = conf.get("email", "from_email")

    message = {
        "senderAddress": sender_address,
        "recipients": recipients,
        "content": {
            "subject": subject,
            "html": html_content,
        },
    }

    poller = client.begin_send(message)
    result = poller.result()
    return result.message_id
