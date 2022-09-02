import os
from datetime import datetime
from typing import Dict, Any

import humanize
import orjson
import pendulum
import structlog
import typer
from calitp.auth import DEFAULT_AUTH_KEYS
from calitp.storage import AirtableGTFSDataRecord, download_feed
from google.cloud import storage
from huey import RedisExpireHuey
from huey.registry import Message
from huey.serializer import Serializer
from requests import HTTPError, RequestException

from .metrics import (
    FETCH_PROCESSING_TIME,
    TASK_SIGNALS,
    FETCH_PROCESSING_DELAY,
    FETCH_PROCESSED_BYTES,
)


class PydanticSerializer(Serializer):
    def _serialize(self, data: Message) -> bytes:
        return orjson.dumps(data._asdict())

    def _deserialize(self, data: bytes) -> Message:
        # deal with datetimes manually
        d = orjson.loads(data)
        d["expires_resolved"] = datetime.fromisoformat(d["expires_resolved"])
        d["kwargs"]["tick"] = datetime.fromisoformat(d["kwargs"]["tick"])
        return Message(*d.values())


huey = RedisExpireHuey(
    name=f"gtfs-rt-archiver-v3-{os.environ['AIRFLOW_ENV']}",
    expire_time=5,
    results=False,
    # serializer=PydanticSerializer(),
    url=os.getenv("CALITP_HUEY_REDIS_URL"),
    host=os.getenv("CALITP_HUEY_REDIS_HOST"),
    port=os.getenv("CALITP_HUEY_REDIS_PORT"),
    password=os.getenv("CALITP_HUEY_REDIS_PASSWORD"),
)


client = storage.Client()

structlog.configure(processors=[structlog.processors.JSONRenderer()])
base_logger = structlog.get_logger()


def record_labels(record: AirtableGTFSDataRecord) -> Dict[str, Any]:
    return dict(
        record_name=record.name,
        record_pipeline_url=record.pipeline_url,
        record_feed_type=record.data,
    )


@huey.signal()
def instrument_signals(signal, task, exc=None):
    TASK_SIGNALS.labels(
        signal=signal,
        exc_type=type(exc).__name__ if exc else "",
        **record_labels(task.kwargs["record"]),
    ).inc()


auth_dict = None


@huey.on_startup()
def load_auth_dict():
    global auth_dict
    auth_dict = {key: os.environ[key] for key in DEFAULT_AUTH_KEYS}


@huey.task(expires=5)
def fetch(tick: datetime, record: AirtableGTFSDataRecord):
    labels = record_labels(record)
    logger = base_logger.bind(
        tick=tick.isoformat(),
        **labels,
    )
    slippage = (pendulum.now() - tick).total_seconds()
    FETCH_PROCESSING_DELAY.labels(**labels).observe(slippage)

    with FETCH_PROCESSING_TIME.labels(**labels).time():
        try:
            extract, content = download_feed(record, auth_dict=auth_dict, ts=tick)
        except HTTPError as e:
            logger.error(
                "unexpected HTTP response code from feed request",
                code=e.response.status_code,
                content=e.response.text,
                exc_type=type(e).__name__,
            )
            raise
        except RequestException as e:
            logger.error(
                "request exception occurred from feed request",
                exc_type=type(e).__name__,
            )
            raise
        except Exception as e:
            logger.error(
                "other non-request exception occurred during download_feed",
                exc_type=type(e).__name__,
            )
            raise

        typer.secho(
            f"saving {humanize.naturalsize(len(content))} from {record.pipeline_url} to {extract.path}"
        )
        extract.save_content(content=content, client=client)
        FETCH_PROCESSED_BYTES.labels(
            **labels,
            content_type=extract.response_headers.get("Content-Type", "").strip(),
        ).inc(len(content))
