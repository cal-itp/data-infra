import os
from datetime import datetime

import google_crc32c
import orjson
import pendulum
from calitp.storage import AirtableGTFSDataRecord, download_feed
from google.cloud import secretmanager, storage
from google.oauth2 import service_account
from huey import RedisHuey
from huey.registry import Message
from huey.serializer import Serializer

from .metrics import (
    HANDLE_TICK_PROCESSING_TIME,
    FEEDS_DOWNLOADED,
    TASK_SIGNALS,
    HANDLE_TICK_PROCESSING_DELAY,
    HANDLE_TICK_PROCESSED_BYTES,
    FEED_REQUEST_FAILURES,
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


huey = RedisHuey(
    name="gtfs-rt-archiver-2",
    results=False,
    # serializer=PydanticSerializer(),
    host="localhost",
)

credentials = service_account.Credentials.from_service_account_file(
    os.getenv("CALITP_DATA_DEST_SECRET")
)
client = storage.Client(credentials=credentials)


@huey.signal()
def instrument_signals(signal, task, exc=None):
    TASK_SIGNALS.labels(signal=signal, exc_type=str(exc)).inc()


auth_dict = {
    key: None
    for key in [
        "AC_TRANSIT_API_KEY",
        "MTC_511_API_KEY",
        "AMTRAK_GTFS_URL",
        "SWIFTLY_AUTHORIZATION_KEY_CALITP",
    ]
}

# TODO: can this be in an on_startup() hook? seems to block with greenlet
print("attempting to populate auth_dict")
secret_client = secretmanager.SecretManagerServiceClient()
for key in auth_dict:
    try:
        auth_dict[key] = os.environ[key]
    except KeyError:
        # TODO: does not work :( something to do with fork and grpc
        print(f"fetching {key}")
        name = f"projects/cal-itp-data-infra/secrets/{key}/versions/latest"
        response = secret_client.access_secret_version(request={"name": name})

        crc32c = google_crc32c.Checksum()
        crc32c.update(response.payload.data)
        if response.payload.data_crc32c != int(crc32c.hexdigest(), 16):
            raise ValueError(f"Data corruption detected for secret {name}.")

        auth_dict[key] = response.payload.data.decode("UTF-8")


@huey.task(expires=5)
def fetch(tick: datetime, record: AirtableGTFSDataRecord):
    slippage = (pendulum.now() - tick).total_seconds()
    HANDLE_TICK_PROCESSING_DELAY.labels(url=record.uri).observe(slippage)

    with HANDLE_TICK_PROCESSING_TIME.labels(url=record.uri).time():
        with FEED_REQUEST_FAILURES.labels(url=record.uri).count_exceptions():
            # TODO: can we either get the content bytes without using memory
            #   or persist on disk in between?
            extract, content = download_feed(record, auth_dict)

        extract.save_content(content=content, client=client)
        HANDLE_TICK_PROCESSED_BYTES.labels(record.uri).inc(len(content))
        FEEDS_DOWNLOADED.labels(url=record.uri).inc()
