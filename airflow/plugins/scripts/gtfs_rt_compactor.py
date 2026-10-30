"""
Compacts one UTC day of raw GTFS-RT fetches into hourly parquet files.

The raw bucket stores one small object per fetch (~27k objects per feed type
per hour). This script reads every object in a (feed_type, dt) partition and
writes one zstd-compressed parquet file per hour to the compacted bucket,
mirroring the raw bucket's partition layout:

    {feed_type}/dt={date}/hour={hour ISO timestamp}/data.parquet

Each row carries the object path, the raw protobuf bytes verbatim, and the
object's PARTITIONED_ARTIFACT_METADATA, which is everything the parser needs
to rebuild a GTFSRTFeedExtract.

Hour files are immutable once published. A run first checks for the final
file and skips any hour that is already archived, reading back the stats the
compactor recorded as object metadata at publish time. New work is staged
under a temporary name and published with a create-only copy
(if_generation_match=0), so nothing ever overwrites an existing archive
file: a retry after a partially failed day compacts only the missing hours,
and concurrent writers of the same hour resolve to a single winner.
Repairing a bad hour therefore requires deliberately deleting the hour file
(and the manifest) before rerunning.

After all hours of a full-day run succeed, {feed_type}/dt={date}/manifest.json
is written next to the data (also create-only) recording listed objects/bytes
and written rows per hour. Per-hour outcomes (including failures and skips)
are saved to the outcomes bucket as
{feed_type}_compaction_outcomes/dt={date}/results.jsonl, following the same
convention as the parser's {feed_type}_outcomes files.

Payload bytes stream through bounded chunks (one parquet row group per
chunk) directly to GCS; the hour's listing (blob handles plus custom
metadata, ~27k entries per feed type per hour) is held in memory.
"""

import datetime
import json
import logging
import os
import sys
from concurrent.futures import ThreadPoolExecutor
from typing import ClassVar, List, Optional

sys.path.append(os.path.normpath(os.path.join(os.path.dirname(__file__), "..")))

import pendulum  # noqa: E402
import pyarrow as pa  # noqa: E402
import pyarrow.parquet as pq  # noqa: E402
import requests  # noqa: E402
import typer  # noqa: E402
from calitp_data_infra.storage import (  # noqa: E402
    PARTITIONED_ARTIFACT_METADATA_KEY,
    GTFSFeedType,
    PartitionedGCSArtifact,
    ProcessingOutcome,
    get_fs,
)
from google.api_core.exceptions import PreconditionFailed  # noqa: E402
from google.cloud import storage  # noqa: E402

RT_FEED_TYPES = ["service_alerts", "trip_updates", "vehicle_positions"]

# One chunk = one parquet row group. Testing on a real sample slice landed on
# 1000 rows as the balance point: ~100MB of payload in flight even on the
# busiest trip_updates hours (a worker task's budget is ~3GB), while keeping
# zstd/dictionary compression within a hair of whole-file ratios.
DEFAULT_CHUNK_SIZE = 1000

COMPACTION_OUTCOMES_BUCKET = os.getenv("CALITP_BUCKET__GTFS_RT_PARSED")

# dt is deliberately not a column: it lives in the hive-style dt= path segment,
# and readers that infer hive partitioning (pyarrow datasets, BigQuery external
# tables) reject files that duplicate a partition column.
SCHEMA = pa.schema(
    [
        ("path", pa.string()),
        ("base64_url", pa.string()),
        ("ts", pa.string()),
        ("feed_type", pa.string()),
        ("metadata", pa.string()),
        ("data", pa.binary()),
    ]
)

app = typer.Typer()


class RTCompactionOutcome(ProcessingOutcome):
    hour: str
    listed_objects: int = 0
    listed_bytes: int = 0
    written_rows: int = 0
    parquet_bytes: int = 0
    parquet_path: Optional[str]


class GTFSRTCompactionJobResult(PartitionedGCSArtifact):
    feed_type: GTFSFeedType
    dt: pendulum.Date
    partition_names: ClassVar[List[str]] = ["dt"]
    outcomes: List[RTCompactionOutcome]

    @property
    def bucket(self) -> Optional[str]:
        return COMPACTION_OUTCOMES_BUCKET

    @property
    def table(self) -> str:
        return f"{self.feed_type.value}_compaction_outcomes"


def partition_value(path: str, key: str) -> str:
    prefix = f"{key}="
    for segment in path.split("/"):
        if segment.startswith(prefix):
            return segment.removeprefix(prefix)
    return ""


def delete_quietly(blob: storage.Blob) -> None:
    try:
        blob.delete()
    except Exception:
        logging.warning(f"could not delete {blob.name}", exc_info=True)


def manifest_name(feed_type: str, dt: str) -> str:
    return f"{feed_type}/dt={dt}/manifest.json"


def storage_client(pool_size: int) -> storage.Client:
    # The client's session keeps only 10 pooled connections by default; with
    # more download threads than that, the overflow opens and discards a
    # connection per request, paying a TLS handshake each time.
    client = storage.Client()
    client._http.mount(
        "https://",
        requests.adapters.HTTPAdapter(
            pool_connections=pool_size, pool_maxsize=pool_size
        ),
    )
    return client


class HourCompaction:
    client: storage.Client
    raw_bucket_name: str
    compacted_bucket: storage.Bucket
    feed_type: str
    dt: str
    hour: int
    workers: int
    chunk_size: int

    def __init__(
        self,
        client: storage.Client,
        raw_bucket_name: str,
        compacted_bucket: storage.Bucket,
        feed_type: str,
        dt: str,
        hour: int,
        workers: int,
        chunk_size: int,
    ) -> None:
        self.client = client
        self.raw_bucket_name = raw_bucket_name
        self.compacted_bucket = compacted_bucket
        self.feed_type = feed_type
        self.dt = dt
        self.hour = hour
        self.workers = workers
        self.chunk_size = chunk_size
        self._blobs: Optional[List[storage.Blob]] = None

    def hour_iso(self) -> str:
        return f"{self.dt}T{self.hour:02d}:00:00+00:00"

    def prefix(self) -> str:
        return f"{self.feed_type}/dt={self.dt}/hour={self.hour_iso()}/"

    def final_name(self) -> str:
        return f"{self.feed_type}/dt={self.dt}/hour={self.hour_iso()}/data.parquet"

    def tmp_name(self) -> str:
        return f"{self.feed_type}/dt={self.dt}/_incoming_hour={self.hour:02d}.parquet"

    def published_blob(self) -> Optional[storage.Blob]:
        return self.compacted_bucket.get_blob(self.final_name())

    def blobs(self) -> List[storage.Blob]:
        if self._blobs is None:
            self._blobs = list(
                self.client.list_blobs(self.raw_bucket_name, prefix=self.prefix())
            )
        return self._blobs

    def listed_bytes(self) -> int:
        return sum(blob.size or 0 for blob in self.blobs())

    def chunk_table(self, chunk: List[storage.Blob], payloads: List[bytes]) -> pa.Table:
        return pa.table(
            {
                "path": [blob.name for blob in chunk],
                "base64_url": [
                    partition_value(blob.name, "base64_url") for blob in chunk
                ],
                "ts": [partition_value(blob.name, "ts") for blob in chunk],
                "feed_type": [self.feed_type] * len(chunk),
                "metadata": [
                    (blob.metadata or {}).get(PARTITIONED_ARTIFACT_METADATA_KEY)
                    for blob in chunk
                ],
                "data": payloads,
            },
            schema=SCHEMA,
        )

    def write_parquet(self, tmp_blob: storage.Blob) -> int:
        """Stream the hour's objects into a staged parquet file, chunk by chunk.

        The sink is a GCS resumable upload: bytes ship as the buffer fills,
        nothing lands on local disk, and the object only materializes in the
        bucket when the stream closes. ParquetWriter appends to it
        incrementally — each loop pass downloads one chunk of payloads on the
        thread pool (pool.map returns results in listing order, keeping paths,
        metadata, and bytes aligned) and writes them as one zstd-compressed
        row group, then drops them. Peak memory is therefore one chunk plus
        buffers, regardless of hour size. The file is unreadable until
        close() writes the parquet footer; deleting the staged object when
        anything here raises is the caller's responsibility.
        """
        written_rows = 0
        with ThreadPoolExecutor(max_workers=self.workers) as pool:
            with tmp_blob.open("wb", ignore_flush=True) as sink:
                writer = pq.ParquetWriter(sink, SCHEMA, compression="zstd")
                try:
                    for offset in range(0, len(self.blobs()), self.chunk_size):
                        end = offset + self.chunk_size
                        chunk = self.blobs()[offset:end]
                        payloads = list(
                            pool.map(lambda blob: blob.download_as_bytes(), chunk)
                        )
                        writer.write_table(self.chunk_table(chunk, payloads))
                        written_rows += len(chunk)
                        logging.debug(
                            f"{self.prefix()}: {written_rows}/{len(self.blobs())} rows"
                        )
                finally:
                    writer.close()
        return written_rows

    def published_outcome(self, blob: storage.Blob) -> RTCompactionOutcome:
        recorded = (blob.metadata or {}).get(PARTITIONED_ARTIFACT_METADATA_KEY)
        if not recorded:
            raise RuntimeError(
                f"{blob.name} exists without compactor metadata; "
                "delete it deliberately before recompacting this hour"
            )
        stats = json.loads(recorded)
        logging.info(f"{self.final_name()}: already archived, skipping")
        return RTCompactionOutcome(
            success=True,
            exception=None,
            hour=self.hour_iso(),
            listed_objects=stats["listed_objects"],
            listed_bytes=stats["listed_bytes"],
            written_rows=stats["written_rows"],
            parquet_bytes=blob.size or 0,
            parquet_path=self.final_name(),
        )

    def compact(self) -> RTCompactionOutcome:
        start = datetime.datetime.now(tz=datetime.timezone.utc)

        published = self.published_blob()
        if published is not None:
            return self.published_outcome(published)

        if not self.blobs():
            logging.info(f"{self.prefix()}: no objects, skipping")
            return RTCompactionOutcome(
                success=True, exception=None, hour=self.hour_iso()
            )

        tmp_blob = self.compacted_bucket.blob(self.tmp_name())
        try:
            written_rows = self.write_parquet(tmp_blob)
            if written_rows != len(self.blobs()):
                raise RuntimeError(
                    f"{self.prefix()}: wrote {written_rows} rows "
                    f"but listed {len(self.blobs())} objects"
                )
            tmp_blob.metadata = {
                PARTITIONED_ARTIFACT_METADATA_KEY: json.dumps(
                    {
                        "hour": self.hour_iso(),
                        "listed_objects": len(self.blobs()),
                        "listed_bytes": self.listed_bytes(),
                        "written_rows": written_rows,
                    }
                )
            }
            tmp_blob.patch()
        except BaseException:
            delete_quietly(tmp_blob)
            raise

        tmp_blob.reload()
        try:
            self.compacted_bucket.copy_blob(
                tmp_blob,
                self.compacted_bucket,
                self.final_name(),
                if_generation_match=0,
            )
        except PreconditionFailed:
            delete_quietly(tmp_blob)
            logging.info(
                f"{self.final_name()} was published by another writer; keeping theirs"
            )
            return self.published_outcome(self.published_blob())
        delete_quietly(tmp_blob)

        elapsed = (
            datetime.datetime.now(tz=datetime.timezone.utc) - start
        ).total_seconds()
        logging.info(
            f"{self.prefix()}: {len(self.blobs())} objects "
            f"({self.listed_bytes() / 1024 / 1024:.1f} MiB) -> {self.final_name()} "
            f"({tmp_blob.size / 1024 / 1024:.1f} MiB) in {elapsed:.0f}s"
        )
        return RTCompactionOutcome(
            success=True,
            exception=None,
            hour=self.hour_iso(),
            listed_objects=len(self.blobs()),
            listed_bytes=self.listed_bytes(),
            written_rows=written_rows,
            parquet_bytes=tmp_blob.size,
            parquet_path=self.final_name(),
        )


class DayCompaction:
    client: storage.Client
    raw_bucket_name: str
    compacted_bucket: storage.Bucket
    feed_type: str
    dt: str
    hours: List[int]
    workers: int
    chunk_size: int

    def __init__(
        self,
        client: storage.Client,
        raw_bucket_name: str,
        compacted_bucket: storage.Bucket,
        feed_type: str,
        dt: str,
        hours: List[int],
        workers: int,
        chunk_size: int,
    ) -> None:
        self.client = client
        self.raw_bucket_name = raw_bucket_name
        self.compacted_bucket = compacted_bucket
        self.feed_type = feed_type
        self.dt = dt
        self.hours = hours
        self.workers = workers
        self.chunk_size = chunk_size
        self._outcomes: Optional[List[RTCompactionOutcome]] = None

    def hour_compaction(self, hour: int) -> HourCompaction:
        return HourCompaction(
            client=self.client,
            raw_bucket_name=self.raw_bucket_name,
            compacted_bucket=self.compacted_bucket,
            feed_type=self.feed_type,
            dt=self.dt,
            hour=hour,
            workers=self.workers,
            chunk_size=self.chunk_size,
        )

    def outcomes(self) -> List[RTCompactionOutcome]:
        if self._outcomes is None:
            self._outcomes = []
            for hour in self.hours:
                try:
                    self._outcomes.append(self.hour_compaction(hour).compact())
                except Exception as e:
                    logging.exception(
                        f"failed compacting {self.feed_type}/dt={self.dt} hour {hour}"
                    )
                    self._outcomes.append(
                        RTCompactionOutcome(
                            success=False,
                            exception=e,
                            hour=f"{self.dt}T{hour:02d}:00:00+00:00",
                        )
                    )
        return self._outcomes

    def failed_hours(self) -> List[str]:
        return [o.hour for o in self.outcomes() if not o.success]

    def write_manifest(self) -> dict:
        hours = [
            {
                "hour": o.hour,
                "listed_objects": o.listed_objects,
                "listed_bytes": o.listed_bytes,
                "written_rows": o.written_rows,
                "parquet_bytes": o.parquet_bytes,
                "parquet_path": o.parquet_path,
            }
            for o in self.outcomes()
        ]
        manifest = {
            "feed_type": self.feed_type,
            "dt": self.dt,
            "raw_bucket": self.raw_bucket_name,
            "compacted_at": datetime.datetime.now(tz=datetime.timezone.utc).isoformat(),
            "listed_objects": sum(h["listed_objects"] for h in hours),
            "listed_bytes": sum(h["listed_bytes"] for h in hours),
            "written_rows": sum(h["written_rows"] for h in hours),
            "parquet_bytes": sum(h["parquet_bytes"] for h in hours),
            "hours": hours,
        }
        blob = self.compacted_bucket.blob(manifest_name(self.feed_type, self.dt))
        try:
            blob.upload_from_string(
                json.dumps(manifest, indent=2),
                content_type="application/json",
                if_generation_match=0,
            )
        except PreconditionFailed:
            logging.info(f"{blob.name} already exists; keeping the original")
        return manifest


@app.command()
def compact(
    feed_type: str = typer.Argument(..., help=f"one of {RT_FEED_TYPES}"),
    dt: str = typer.Argument(..., help="UTC date to compact, YYYY-MM-DD"),
    hour: Optional[int] = typer.Option(
        None, min=0, max=23, help="compact a single hour instead of the full day"
    ),
    raw_bucket: str = typer.Option(None, envvar="CALITP_BUCKET__GTFS_RT_RAW"),
    compacted_bucket: str = typer.Option(
        None, envvar="CALITP_BUCKET__GTFS_RT_RAW_COMPACTED"
    ),
    outcomes_bucket: str = typer.Option(
        None,
        envvar="CALITP_BUCKET__GTFS_RT_PARSED",
        help="bucket receiving compaction outcome files",
    ),
    workers: int = typer.Option(32, min=1, help="concurrent GCS downloads"),
    chunk_size: int = typer.Option(
        DEFAULT_CHUNK_SIZE, min=1, help="rows held in memory per row group"
    ),
    verbose: bool = False,
):
    global COMPACTION_OUTCOMES_BUCKET

    logging.basicConfig(level=logging.DEBUG if verbose else logging.INFO)

    if feed_type not in RT_FEED_TYPES:
        raise typer.BadParameter(f"feed_type must be one of {RT_FEED_TYPES}")
    dt = datetime.date.fromisoformat(dt).isoformat()
    if not raw_bucket or not compacted_bucket:
        raise typer.BadParameter(
            "raw and compacted buckets must be set via options or "
            "CALITP_BUCKET__GTFS_RT_RAW / CALITP_BUCKET__GTFS_RT_RAW_COMPACTED"
        )
    full_day = hour is None
    if full_day and not outcomes_bucket:
        raise typer.BadParameter(
            "outcomes bucket must be set via --outcomes-bucket or "
            "CALITP_BUCKET__GTFS_RT_PARSED"
        )

    # Hour files and manifests are immutable once published, so archiving a
    # partition that is still being written would freeze it incomplete.
    partition_end = datetime.datetime.fromisoformat(dt).replace(
        tzinfo=datetime.timezone.utc
    ) + (datetime.timedelta(days=1) if full_day else datetime.timedelta(hours=hour + 1))
    if datetime.datetime.now(tz=datetime.timezone.utc) < partition_end:
        # RuntimeError rather than BadParameter: typer 0.4.1 cannot render
        # usage errors under the Composer image's click 8.2, which would
        # swallow this message in task logs.
        raise RuntimeError(
            f"{feed_type}/dt={dt} is not fully in the past; "
            "refusing to archive an incomplete partition"
        )
    COMPACTION_OUTCOMES_BUCKET = (outcomes_bucket or "").removeprefix("gs://") or None

    client = storage_client(pool_size=workers)
    day = DayCompaction(
        client=client,
        raw_bucket_name=raw_bucket.removeprefix("gs://"),
        compacted_bucket=client.bucket(compacted_bucket.removeprefix("gs://")),
        feed_type=feed_type,
        dt=dt,
        hours=list(range(24)) if full_day else [hour],
        workers=workers,
        chunk_size=chunk_size,
    )
    outcomes = day.outcomes()

    if full_day:
        result = GTFSRTCompactionJobResult(
            filename="results.jsonl",
            feed_type=GTFSFeedType(feed_type),
            dt=pendulum.parse(dt).date(),
            outcomes=outcomes,
        )
        logging.info(f"saving {len(outcomes)} outcomes to {result.path}")
        content = "\n".join(o.json() for o in outcomes).encode("utf-8")
        result.save_content(fs=get_fs(), content=content, exclude={"outcomes"})

        if not day.failed_hours():
            manifest = day.write_manifest()
            logging.info(
                f"{feed_type}/dt={dt}: {manifest['listed_objects']} objects "
                f"({manifest['listed_bytes'] / 1024 / 1024:.1f} MiB) -> "
                f"{sum(1 for h in manifest['hours'] if h['written_rows'])} parquet "
                f"files ({manifest['parquet_bytes'] / 1024 / 1024:.1f} MiB)"
            )

    if day.failed_hours():
        raise RuntimeError(f"{feed_type}/dt={dt}: failed hours {day.failed_hours()}")


if __name__ == "__main__":
    app()
