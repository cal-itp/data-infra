"""Live checks of the compacted archive against real GCS.

Write-once makes a naive live write test unrepeatable (a rerun skips every
published hour), so live coverage is split in two:

- test_archive_readback_live reads the synthetic fixture partition that
  test_gtfs_rt_compactor_vcr.py records and verifies a consumer can rebuild
  every payload and its metadata from the archive alone. Read-only in the
  normal case; the compacted side lives in calitp-staging-pytest-parsed
  (staging's 90-day cleanup), so it recompacts the fixture from the raw
  fixture objects (calitp-staging-pytest, no lifecycle) when swept.
- test_repair_and_recompact_live exercises the full live write path every
  run by performing the documented repair procedure on its own partition:
  delete the hour file and manifest, rerun the day, verify the archive is
  rebuilt. This is the one mutation the design permits, and it doubles as a
  standing rehearsal of the operator repair runbook.

Both require staging access, like the parser's live tests. Racing CI builds
resolve through the create-only publish.
"""

import datetime
import io
import json

import pyarrow.parquet as pq
from google.api_core.exceptions import NotFound, PreconditionFailed
from google.cloud import storage
from scripts import gtfs_rt_compactor as compactor
from test_gtfs_rt_compactor_vcr import (
    DT,
    FEED_TYPE,
    FINAL_NAME,
    MANIFEST_NAME,
    OUT_BUCKET,
    OUTCOMES_NAME,
    PAYLOADS,
)
from typer.testing import CliRunner

RAW_BUCKET = "calitp-staging-pytest"
# The repair test mutates its own partition; the readback fixture stays frozen.
REPAIR_DT = "2001-10-29"


def source_name(dt, i):
    ts = f"{dt}T10:00:{i * 20:02d}+00:00"
    return (
        f"{FEED_TYPE}/dt={dt}/hour={dt}T10:00:00+00:00/ts={ts}/base64_url=dGVzdA==/feed"
    )


def expected_rows(dt):
    rows = []
    for i, payload in enumerate(PAYLOADS):
        ts = f"{dt}T10:00:{i * 20:02d}+00:00"
        rows.append(
            {
                "path": source_name(dt, i),
                "base64_url": "dGVzdA==",
                "ts": ts,
                "feed_type": FEED_TYPE,
                "metadata": json.dumps({"filename": "feed", "ts": ts, "fixture": True}),
                "data": payload,
            }
        )
    return rows


def set_buckets(monkeypatch):
    monkeypatch.setenv("CALITP_BUCKET__GTFS_RT_RAW", f"gs://{RAW_BUCKET}")
    monkeypatch.setenv("CALITP_BUCKET__GTFS_RT_RAW_COMPACTED", f"gs://{OUT_BUCKET}")
    monkeypatch.setenv("CALITP_BUCKET__GTFS_RT_PARSED", f"gs://{OUT_BUCKET}")


def ensure_sources(client, dt):
    for i, payload in enumerate(PAYLOADS):
        ts = f"{dt}T10:00:{i * 20:02d}+00:00"
        blob = client.bucket(RAW_BUCKET).blob(source_name(dt, i))
        blob.metadata = {
            compactor.PARTITIONED_ARTIFACT_METADATA_KEY: json.dumps(
                {"filename": "feed", "ts": ts, "fixture": True}
            )
        }
        try:
            blob.upload_from_string(payload, if_generation_match=0)
        except PreconditionFailed:
            pass


def read_archive(bucket, dt, manifest_name, final_name, outcomes_name):
    manifest = json.loads(bucket.blob(manifest_name).download_as_bytes())
    assert manifest["listed_objects"] == manifest["written_rows"] == len(PAYLOADS)
    assert manifest["listed_bytes"] == sum(map(len, PAYLOADS))
    hour_entries = [h for h in manifest["hours"] if h["written_rows"]]
    assert len(hour_entries) == 1
    assert hour_entries[0]["parquet_path"] == final_name

    final = bucket.get_blob(final_name)
    stamped = json.loads(final.metadata[compactor.PARTITIONED_ARTIFACT_METADATA_KEY])
    assert stamped["written_rows"] == len(PAYLOADS)
    assert stamped["listed_bytes"] == manifest["listed_bytes"]

    table = pq.ParquetFile(io.BytesIO(final.download_as_bytes())).read()
    assert table.to_pylist() == expected_rows(dt)

    outcomes = [
        json.loads(line)
        for line in bucket.blob(outcomes_name).download_as_bytes().splitlines()
    ]
    assert len(outcomes) == 24
    assert sum(o["written_rows"] for o in outcomes) == len(PAYLOADS)
    assert all(o["success"] for o in outcomes)
    return manifest


def test_archive_readback_live(monkeypatch):
    client = storage.Client()
    if client.bucket(OUT_BUCKET).get_blob(MANIFEST_NAME) is None:
        set_buckets(monkeypatch)
        result = CliRunner().invoke(compactor.app, [FEED_TYPE, DT, "--chunk-size", "2"])
        assert result.exit_code == 0, result.exception

    read_archive(
        client.bucket(OUT_BUCKET), DT, MANIFEST_NAME, FINAL_NAME, OUTCOMES_NAME
    )


def test_repair_and_recompact_live(monkeypatch):
    client = storage.Client()
    ensure_sources(client, REPAIR_DT)
    bucket = client.bucket(OUT_BUCKET)
    final_name = (
        f"{FEED_TYPE}/dt={REPAIR_DT}/hour={REPAIR_DT}T10:00:00+00:00/data.parquet"
    )
    manifest_name = f"{FEED_TYPE}/dt={REPAIR_DT}/manifest.json"
    outcomes_name = f"{FEED_TYPE}_compaction_outcomes/dt={REPAIR_DT}/results.jsonl"

    # The documented repair procedure: delete the hour file and the manifest,
    # then rerun the day.
    for name in (final_name, manifest_name):
        try:
            bucket.blob(name).delete()
        except NotFound:
            pass

    started = datetime.datetime.now(tz=datetime.timezone.utc)
    set_buckets(monkeypatch)
    result = CliRunner().invoke(
        compactor.app, [FEED_TYPE, REPAIR_DT, "--chunk-size", "2"]
    )
    assert result.exit_code == 0, result.exception

    manifest = read_archive(bucket, REPAIR_DT, manifest_name, final_name, outcomes_name)
    compacted_at = datetime.datetime.fromisoformat(manifest["compacted_at"])
    assert compacted_at >= started
