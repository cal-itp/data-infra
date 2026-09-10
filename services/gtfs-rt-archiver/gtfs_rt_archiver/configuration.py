import logging
import math
import os
import threading
from base64 import urlsafe_b64encode
from datetime import datetime
from typing import Self, Type

from google.auth import default
from google.cloud.secretmanager import SecretManagerServiceClient

# One Secret Manager client per warm instance, same rationale as the GCS client
# in archiver.py: single-tenant Google API calls with this service's own
# credentials, so sharing it across requests is safe and avoids a per-read token
# round-trip. Only auth feeds hit this path.
_secret_client: SecretManagerServiceClient | None = None
_secret_client_lock = threading.Lock()


def shared_secret_client() -> SecretManagerServiceClient:
    global _secret_client
    if _secret_client is None:
        with _secret_client_lock:
            if _secret_client is None:
                _secret_client = SecretManagerServiceClient()
    return _secret_client


HEADERS = {
    "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/145.0.0.0 Safari/537.36",
    "Accept": "application/x-protobuf,text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7",
    "Accept-Language": "en-US,en;q=0.9",
    "Connection": "keep-alive",
    "Upgrade-Insecure-Requests": "1",
    "Sec-Ch-Ua": '"Not:A-Brand";v="99", "Google Chrome";v="145", "Chromium";v="145',
    "Sec-Fetch-Dest": "document",
    "Sec-Fetch-Mode": "navigate",
    "Sec-Fetch-Site": "cross-site",
    "Sec-Fetch-User": "?1",
    "Cache-Control": "max-age=0",
}


class Secret:
    def __init__(self, project_id: str, name: str) -> None:
        self.project_id: str = project_id
        self.name: str = name

    def client(self) -> SecretManagerServiceClient:
        return shared_secret_client()

    def secret_name(self) -> str:
        return os.path.join(
            "projects", self.project_id, "secrets", self.name, "versions", "latest"
        )

    def get(self) -> str:
        if self.name is not None:
            return (
                self.client()
                .access_secret_version(name=self.secret_name())
                .payload.data.decode("UTF-8")
            )
        return None


class Configuration:
    def __init__(
        self,
        project_id: str,
        destination_bucket: str,
        publish_time: datetime,
        auth_headers: dict,
        auth_query_params: dict,
        extracted_at: str,
        feed_type: str,
        name: str,
        schedule_url_for_validation: str,
        url: str,
        computed: bool,
        batch_at: str = None,
        secret_resolver: Type = Secret,
        **extras,
    ) -> None:
        self.project_id: str = project_id
        self.destination_bucket: str = destination_bucket
        self.publish_time: datetime = publish_time
        self.auth_headers: dict = auth_headers
        self.auth_query_params: dict = auth_query_params
        self.extracted_at: datetime = datetime.fromisoformat(extracted_at)
        self.feed_type: str = feed_type
        self.name: str = name
        self.schedule_url_for_validation: str = schedule_url_for_validation
        self.url: str = url
        self.computed: bool = computed
        # Only the high-frequency clock stamps batch_at onto its messages. When it
        # is present it is the authoritative timestamp: batch times sit on an exact
        # grid, so partitions cannot collide no matter how much fan-out jitter a
        # tick picks up. Production messages carry no batch_at and keep the legacy
        # 20-second floor below.
        self.batch_at: datetime | None = (
            datetime.fromisoformat(batch_at) if batch_at else None
        )
        self.secret_resolver: Type = secret_resolver
        if extras:
            logging.warning(f"Unsupported keys {list(extras.keys())}")

    def __eq__(self, other: Self) -> bool:
        if not isinstance(other, Configuration):
            return NotImplemented

        return self.name == other.name and self.extracted_at == other.extracted_at

    def timestamp(self) -> datetime:
        return self.batch_at or self.publish_time

    def dt(self) -> str:
        return self.timestamp().date().isoformat()

    def hour(self) -> str:
        return self.timestamp().replace(minute=0, second=0, microsecond=0).isoformat()

    def ts(self) -> str:
        # dt/hour/ts must all derive from the same instant. A tick that straddles an
        # hour (published 12:59:59, batched 13:00:02) would otherwise write
        # hour=12:00.../ts=13:00:02, which the RT parser cross-checks and rejects.
        if self.batch_at is not None:
            return self.batch_at.isoformat()

        seconds = math.floor(self.timestamp().second / 20) * 20
        return self.timestamp().replace(microsecond=0, second=seconds).isoformat()

    def base64_url(self) -> str:
        return urlsafe_b64encode(self.url.encode()).decode()

    def destination_prefix(self) -> str:
        return os.path.join(
            self.feed_type,
            f"dt={self.dt()}",
            f"hour={self.hour()}",
            f"ts={self.ts()}",
            f"base64_url={self.base64_url()}",
        )

    def headers(self) -> dict:
        result = {}
        for key, value in self.auth_headers.items():
            result[key] = self.secret_resolver(
                project_id=self.project_id, name=value
            ).get()
        return HEADERS | result

    def params(self) -> dict:
        result = {}
        for key, value in self.auth_query_params.items():
            result[key] = self.secret_resolver(
                project_id=self.project_id, name=value
            ).get()
        return result

    def json(self) -> dict:
        return {
            "extracted_at": self.extracted_at.isoformat(),
            "name": self.name,
            "url": self.url,
            "feed_type": self.feed_type,
            "schedule_url_for_validation": self.schedule_url_for_validation,
            "auth_query_params": self.auth_query_params,
            "auth_headers": self.auth_headers,
            "computed": self.computed,
        }

    @staticmethod
    def resolve(publish_time: datetime, **settings: dict) -> Self:
        _, project_id = default()
        return Configuration(
            project_id=project_id,
            destination_bucket=os.environ["CALITP_BUCKET__GTFS_RT_RAW"],
            publish_time=publish_time,
            **settings,
        )
