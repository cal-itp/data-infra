"""Replay the full CLI with real storage clients; see scripts/README.md to record."""

import io
import json
from urllib.parse import parse_qsl, urlencode, urlsplit, urlunsplit

import google.auth
import pyarrow.parquet as pq
import pytest
from google.auth.credentials import AnonymousCredentials
from google.cloud import storage
from google.cloud.storage.fileio import BlobWriter
from scripts import gtfs_rt_compactor as compactor
from typer.testing import CliRunner

PROJECT = "cal-itp-data-infra-staging"
RAW_BUCKET = "calitp-staging-pytest"
OUT_BUCKET = "calitp-staging-pytest-parsed"
# A dedicated synthetic partition, outside the dates used by pipeline fixtures.
# Must be in the past (the CLI refuses incomplete partitions); choose a fresh
# date when recording again; the preflight refuses existing data.
DT = "2001-10-28"
FEED_TYPE = "service_alerts"
PREFIX = f"{FEED_TYPE}/dt={DT}/"
FINAL_NAME = f"{PREFIX}hour={DT}T10:00:00+00:00/data.parquet"
TMP_NAME = f"{PREFIX}_incoming_hour=10.parquet"
MANIFEST_NAME = f"{PREFIX}manifest.json"
OUTCOMES_NAME = f"{FEED_TYPE}_compaction_outcomes/dt={DT}/results.jsonl"
PAYLOADS = [b"\x0a\x05\x0a\x03" + b"2.0", b"", b"\xffHTTP error response"]


def scrub_upload_session(response):
    """Keep resumable-upload capabilities out of the committed cassette."""
    for key, values in response["headers"].items():
        if key.lower() == "x-guploader-uploadid":
            response["headers"][key] = ["FILTERED"]
        if key.lower() == "location":
            cleaned = []
            for value in values:
                url = urlsplit(value)
                query = [
                    (k, "FILTERED" if k == "upload_id" else v)
                    for k, v in parse_qsl(url.query)
                ]
                cleaned.append(urlunsplit(url._replace(query=urlencode(query))))
            response["headers"][key] = cleaned
    return response


@pytest.fixture
def vcr_config():
    return {
        "filter_headers": ["authorization", "cookie"],
        "filter_query_parameters": [("upload_id", "FILTERED")],
        "before_record_response": scrub_upload_session,
        # Authentication is live only when deliberately recording. Playback
        # supplies anonymous credentials below and does not contact these hosts.
        "ignore_hosts": [
            "sts.googleapis.com",
            "iamcredentials.googleapis.com",
            "oauth2.googleapis.com",
        ],
    }


@pytest.mark.vcr
def test_compact_cli_full_day(monkeypatch, vcr, record_mode):
    monkeypatch.setenv("GOOGLE_CLOUD_PROJECT", PROJECT)
    monkeypatch.setenv("CALITP_BUCKET__GTFS_RT_RAW", f"gs://{RAW_BUCKET}")
    monkeypatch.setenv("CALITP_BUCKET__GTFS_RT_RAW_COMPACTED", f"gs://{OUT_BUCKET}")
    monkeypatch.setenv("CALITP_BUCKET__GTFS_RT_PARSED", f"gs://{OUT_BUCKET}")
    monkeypatch.delenv("CALITP_AUTH", raising=False)
    if record_mode == "none":
        monkeypatch.setattr(
            google.auth,
            "default",
            lambda **kwargs: (AnonymousCredentials(), PROJECT),
        )

    # Use the real gcsfs outcome writer without reusing another test's credentials.
    get_fs = compactor.get_fs
    monkeypatch.setattr(compactor, "get_fs", lambda: get_fs(skip_instance_cache=True))
    monkeypatch.setattr(compactor, "COMPACTION_OUTCOMES_BUCKET", None)

    client = storage.Client()
    # Recording creates only this test's objects. Refuse to overwrite a previous
    # recording or another fixture; the same preflight is replayed in CI.
    for bucket, prefix in [
        (RAW_BUCKET, PREFIX),
        (OUT_BUCKET, PREFIX),
        (OUT_BUCKET, OUTCOMES_NAME),
    ]:
        assert not list(
            client.list_blobs(bucket, prefix=prefix, max_results=1)
        ), "Recording partition already exists; choose a fresh fixture date"

    expected_rows = []
    for i, payload in enumerate(PAYLOADS):
        ts = f"{DT}T10:00:{i * 20:02d}+00:00"
        name = f"{PREFIX}hour={DT}T10:00:00+00:00/ts={ts}/base64_url=dGVzdA==/feed"
        metadata = json.dumps({"filename": "feed", "ts": ts, "fixture": True})
        blob = client.bucket(RAW_BUCKET).blob(name)
        blob.metadata = {compactor.PARTITIONED_ARTIFACT_METADATA_KEY: metadata}
        blob.upload_from_string(payload, if_generation_match=0)
        expected_rows.append(
            {
                "path": name,
                "base64_url": "dGVzdA==",
                "ts": ts,
                "feed_type": FEED_TYPE,
                "metadata": metadata,
                "data": payload,
            }
        )

    # Observe current-run writes while still executing the real clients. Reading
    # output through VCR alone would return recorded bytes and could hide bugs.
    parquet_bytes = bytearray()
    written_manifest = []
    written_outcomes = []
    write = BlobWriter.write
    upload = storage.Blob.upload_from_string
    save = compactor.GTFSRTCompactionJobResult.save_content

    def observe_write(self, data):
        count = write(self, data)
        parquet_bytes.extend(data)
        return count

    def observe_upload(self, data, *args, **kwargs):
        if self.name == MANIFEST_NAME:
            written_manifest.append(json.loads(data))
        return upload(self, data, *args, **kwargs)

    def observe_outcomes(self, *args, **kwargs):
        assert self.path == f"{OUT_BUCKET}/{OUTCOMES_NAME}"
        written_outcomes.extend(
            json.loads(line) for line in kwargs["content"].splitlines()
        )
        return save(self, *args, **kwargs)

    monkeypatch.setattr(BlobWriter, "write", observe_write)
    monkeypatch.setattr(storage.Blob, "upload_from_string", observe_upload)
    monkeypatch.setattr(
        compactor.GTFSRTCompactionJobResult, "save_content", observe_outcomes
    )
    result = CliRunner().invoke(
        compactor.app,
        [FEED_TYPE, DT, "--workers", "1", "--chunk-size", "2"],
    )
    assert result.exit_code == 0, result.exception

    parquet = pq.ParquetFile(io.BytesIO(parquet_bytes))
    assert parquet.num_row_groups == 2
    assert parquet.read().to_pylist() == expected_rows
    assert len(written_manifest) == 1
    manifest = written_manifest[0]
    assert manifest["feed_type"] == FEED_TYPE
    assert manifest["dt"] == DT
    assert manifest["raw_bucket"] == RAW_BUCKET
    assert manifest["listed_objects"] == manifest["written_rows"] == len(PAYLOADS)
    assert manifest["listed_bytes"] == sum(map(len, PAYLOADS))
    assert manifest["parquet_bytes"] == len(parquet_bytes)
    assert len(manifest["hours"]) == len(written_outcomes) == 24
    for hour, (stats, outcome) in enumerate(zip(manifest["hours"], written_outcomes)):
        assert outcome["success"] is True
        assert outcome["exception"] is None
        assert stats["hour"] == outcome["hour"] == f"{DT}T{hour:02d}:00:00+00:00"
        for key in (
            "listed_objects",
            "listed_bytes",
            "written_rows",
            "parquet_bytes",
            "parquet_path",
        ):
            assert stats[key] == outcome[key]
        assert stats["written_rows"] == (len(PAYLOADS) if hour == 10 else 0)
        assert stats["parquet_path"] == (FINAL_NAME if hour == 10 else None)

    # These readbacks also exercise publication, cleanup, and outcome metadata.
    bucket = client.bucket(OUT_BUCKET)
    assert bucket.blob(FINAL_NAME).download_as_bytes() == bytes(parquet_bytes)
    assert not bucket.blob(TMP_NAME).exists()
    saved_manifest = json.loads(bucket.blob(MANIFEST_NAME).download_as_bytes())
    assert saved_manifest["hours"] == manifest["hours"]
    outcome_blob = bucket.get_blob(OUTCOMES_NAME)
    assert outcome_blob is not None
    assert "outcomes" not in json.loads(
        outcome_blob.metadata[compactor.PARTITIONED_ARTIFACT_METADATA_KEY]
    )
    saved_outcomes = [
        json.loads(line) for line in outcome_blob.download_as_bytes().splitlines()
    ]
    assert saved_outcomes == written_outcomes
    assert vcr.all_played or record_mode != "none"
