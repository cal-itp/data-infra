"""Live read-side checks of the compacted-archive format against real GCS.

Write-once makes live write tests unrepeatable (a rerun skips every published
hour), but extraction must stay provable against real storage forever. This
test reads the synthetic fixture partition that test_gtfs_rt_compactor_vcr.py
records, in the staging pytest buckets, and verifies a consumer can rebuild
every payload and its metadata from the archive alone.

The compacted side lives in calitp-staging-pytest-parsed, which has staging's
90-day cleanup, so the test first ensures the fixture exists and recompacts it
from the raw fixture objects (calitp-staging-pytest, no lifecycle) when it has
been cleaned up. When the fixture exists this is read-only; racing CI builds
resolve through the create-only publish. Requires staging access, like the
parser's live tests.
"""

import io
import json

import pyarrow.parquet as pq
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
    PREFIX,
)
from typer.testing import CliRunner


def expected_rows():
    rows = []
    for i, payload in enumerate(PAYLOADS):
        ts = f"{DT}T10:00:{i * 20:02d}+00:00"
        name = f"{PREFIX}hour={DT}T10:00:00+00:00/ts={ts}/base64_url=dGVzdA==/feed"
        rows.append(
            {
                "path": name,
                "base64_url": "dGVzdA==",
                "ts": ts,
                "feed_type": FEED_TYPE,
                "metadata": json.dumps({"filename": "feed", "ts": ts, "fixture": True}),
                "data": payload,
            }
        )
    return rows


def ensure_fixture(monkeypatch, client):
    if client.bucket(OUT_BUCKET).get_blob(MANIFEST_NAME) is not None:
        return
    monkeypatch.setenv("CALITP_BUCKET__GTFS_RT_RAW", "gs://calitp-staging-pytest")
    monkeypatch.setenv("CALITP_BUCKET__GTFS_RT_RAW_COMPACTED", f"gs://{OUT_BUCKET}")
    monkeypatch.setenv("CALITP_BUCKET__GTFS_RT_PARSED", f"gs://{OUT_BUCKET}")
    result = CliRunner().invoke(compactor.app, [FEED_TYPE, DT, "--chunk-size", "2"])
    assert result.exit_code == 0, result.exception


def test_archive_readback_live(monkeypatch):
    client = storage.Client()
    ensure_fixture(monkeypatch, client)
    bucket = client.bucket(OUT_BUCKET)

    manifest = json.loads(bucket.blob(MANIFEST_NAME).download_as_bytes())
    assert manifest["listed_objects"] == manifest["written_rows"] == len(PAYLOADS)
    assert manifest["listed_bytes"] == sum(map(len, PAYLOADS))
    hour_entries = [h for h in manifest["hours"] if h["written_rows"]]
    assert len(hour_entries) == 1
    assert hour_entries[0]["parquet_path"] == FINAL_NAME

    final = bucket.get_blob(FINAL_NAME)
    stamped = json.loads(final.metadata[compactor.PARTITIONED_ARTIFACT_METADATA_KEY])
    assert stamped["written_rows"] == len(PAYLOADS)
    assert stamped["listed_bytes"] == manifest["listed_bytes"]

    table = pq.ParquetFile(io.BytesIO(final.download_as_bytes())).read()
    assert table.to_pylist() == expected_rows()

    outcomes = [
        json.loads(line)
        for line in bucket.blob(OUTCOMES_NAME).download_as_bytes().splitlines()
    ]
    assert len(outcomes) == 24
    assert sum(o["written_rows"] for o in outcomes) == len(PAYLOADS)
    assert all(o["success"] for o in outcomes)
