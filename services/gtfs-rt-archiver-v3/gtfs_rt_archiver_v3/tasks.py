import os
import traceback
from datetime import datetime
from functools import wraps
from pathlib import Path
from typing import Mapping, Optional

import humanize
import pendulum
import sentry_sdk
import structlog
import typer
from calitp_data_infra.storage import GTFSDownloadConfig, download_feed  # type: ignore
from google.cloud import storage  # type: ignore
from huey import RedisHuey  # type: ignore
from huey.api import Task  # type: ignore
from pydantic.networks import HttpUrl
from requests import HTTPError, RequestException

from .metrics import (
    FETCH_DOWNLOADING_TIME,
    FETCH_PROCESSED_BYTES,
    FETCH_PROCESSING_DELAY,
    FETCH_PROCESSING_TIME,
    FETCH_UPLOADING_TIME,
    TASK_SIGNALS,
)

# 30 is ridiculously high for a default, but there's a few feeds that commonly take 10+ seconds
FETCH_TIMEOUT_SECONDS = int(os.getenv("CALITP_FETCH_REQUEST_TIMEOUT_SECONDS", 30))


class RedisHueyWithMetrics(RedisHuey):
    pass


huey = RedisHueyWithMetrics(
    name=f"gtfs-rt-archiver-v3-{os.environ['AIRFLOW_ENV']}",
    blocking=os.getenv("CALITP_HUEY_BLOCKING", "true").lower()
    in ("true", "t", "yes", "y", "1"),
    results=False,
    # serializer=PydanticSerializer(),
    url=os.getenv("CALITP_HUEY_REDIS_URL"),
    host=os.getenv("CALITP_HUEY_REDIS_HOST"),
    port=os.getenv("CALITP_HUEY_REDIS_PORT"),
    password=os.getenv("CALITP_HUEY_REDIS_PASSWORD"),
    read_timeout=int(os.getenv("CALITP_HUEY_READ_TIMEOUT", 1)),  # default from huey
)


client = storage.Client()

structlog.configure(processors=[structlog.processors.JSONRenderer()])
base_logger = structlog.get_logger()


class RTFetchException(Exception):
    def __init__(
        self, url: HttpUrl, cause: Exception, status_code: Optional[int] = None
    ):
        self.url = url
        self.cause = cause
        self.status_code = status_code
        super().__init__(str(self.cause))

    def __str__(self) -> str:
        return " ".join(
            [
                type(self.cause).__name__,
                f"({self.status_code})" if self.status_code else "",
                f"{self.url}",
            ]
        )


@huey.signal()
def increment_task_signals_counter(
    signal: str, task: Task, exc: Optional[Exception] = None
) -> None:
    config: GTFSDownloadConfig = task.kwargs["config"]
    exc_type = ""
    # We want to let RTFetchException propagate up to Sentry so it holds the right context
    # and can be handled in the before_send hook
    # But in Grafana/Prometheus we want to group metrics by the underlying cause
    # All of this might be simplified by https://huey.readthedocs.io/en/latest/api.html#Huey.post_execute?
    if exc:
        if isinstance(exc, RTFetchException):
            exc_type = type(exc.cause).__name__
        else:
            exc_type = type(exc).__name__

    TASK_SIGNALS.labels(
        record_name=config.name,
        record_uri=config.url,
        record_feed_type=config.feed_type,
        signal=signal,
        exc_type=exc_type,
    ).inc()


last_fetch_file = None


@huey.on_startup()
def load_globals():
    global last_fetch_file
    last_fetch_file = os.environ["LAST_FETCH_FILE"]


# from https://github.com/getsentry/sentry-python/issues/195#issuecomment-444559126
def scoped(f):
    @wraps(f)
    def inner(*args, **kwargs):
        config: GTFSDownloadConfig = kwargs.get("config")
        # to be honest I don't really know why push_scope() does not work here
        with sentry_sdk.configure_scope() as scope:
            scope.clear_breadcrumbs()
            if config:
                scope.set_tag("config_name", config.name)
                scope.set_tag("config_url", config.url)
                scope.set_context("config", config.dict())
            return f(*args, **kwargs)

    return inner


@huey.task(expires=int(os.getenv("CALITP_FETCH_EXPIRATION_SECONDS", 5)))
@scoped
def fetch(tick: datetime, config: GTFSDownloadConfig, auth_dict: Mapping[str, str]):
    labels = dict(
        record_name=config.name,
        record_uri=config.url,
        record_feed_type=config.feed_type,
    )
    logger = base_logger.bind(
        tick=tick.isoformat(),
        **labels,
    )
    slippage = (pendulum.now() - tick).total_seconds()
    FETCH_PROCESSING_DELAY.labels(**labels).observe(slippage)

    with FETCH_PROCESSING_TIME.labels(**labels).time():
        try:
            with FETCH_DOWNLOADING_TIME.labels(**labels).time():
                extract, content = download_feed(
                    config=config,
                    auth_dict=auth_dict,
                    ts=tick,
                    timeout=FETCH_TIMEOUT_SECONDS,
                )
        except Exception as e:
            status_code = None
            kwargs = dict(
                exc_type=type(e).__name__,
                exc_str=str(e),
                traceback=traceback.format_exc(),
            )
            if isinstance(e, HTTPError):
                msg = "unexpected HTTP response code from feed request"
                status_code = e.response.status_code
                kwargs.update(
                    dict(
                        code=e.response.status_code,  # type: ignore
                        content=e.response.text,
                    )
                )
            elif isinstance(e, RequestException):
                msg = "request exception occurred from feed request"
            else:
                msg = "other non-request exception occurred during download_feed"
            logger.exception(msg, **kwargs)
            raise RTFetchException(config.url, cause=e, status_code=status_code) from e

        typer.secho(
            f"saving {humanize.naturalsize(len(content))} from {config.url} to {extract.path}"
        )
        try:
            with FETCH_UPLOADING_TIME.labels(**labels).time():
                extract.save_content(
                    content=content, client=client, retry_metadata=True
                )
        except Exception as e:
            logger.exception(
                "failure occurred when saving extract or metadata",
                exc_type=type(e).__name__,
                exc_str=str(e),
                traceback=traceback.format_exc(),
            )
            raise
        FETCH_PROCESSED_BYTES.labels(
            **labels,
            content_type=extract.response_headers.get("Content-Type", "").strip(),
        ).inc(len(content))
        Path(last_fetch_file).touch()  # type: ignore
