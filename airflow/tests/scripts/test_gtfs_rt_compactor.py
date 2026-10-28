import datetime
import hashlib
import json
import shutil
from pathlib import Path

import pyarrow.parquet as pq
import pytest
from google.api_core.exceptions import PreconditionFailed
from scripts import gtfs_rt_compactor as compactor
from typer.testing import CliRunner

FEED_TYPE = "service_alerts"
DT = "2026-08-12"
HOUR = 10
HOUR_ISO = f"{DT}T{HOUR:02d}:00:00+00:00"
FINAL_NAME = f"{FEED_TYPE}/dt={DT}/hour={HOUR_ISO}/data.parquet"
TMP_NAME = f"{FEED_TYPE}/dt={DT}/_incoming_hour={HOUR:02d}.parquet"
MANIFEST_NAME = f"{FEED_TYPE}/dt={DT}/manifest.json"


class FakeBlob:
    def __init__(self, name, data, metadata):
        self.name = name
        self.data = data
        self.metadata = metadata
        self.size = len(data)
        self.fail = False

    def download_as_bytes(self):
        if self.fail:
            raise ConnectionError("simulated download failure")
        return self.data


class FakeOutBlob:
    def __init__(self, bucket, name):
        self._bucket = bucket
        self._path = bucket.root / name
        self.name = name
        self.size = None
        self.metadata = bucket.metadata_by_name.get(name)

    def open(self, mode, ignore_flush=False):
        self._path.parent.mkdir(parents=True, exist_ok=True)
        return open(self._path, mode)

    def reload(self):
        self.size = self._path.stat().st_size
        self.metadata = self._bucket.metadata_by_name.get(self.name)

    def exists(self):
        return self._path.exists()

    def delete(self):
        self._path.unlink()
        self._bucket.metadata_by_name.pop(self.name, None)

    def patch(self):
        self._bucket.metadata_by_name[self.name] = self.metadata

    def upload_from_string(self, data, content_type=None, if_generation_match=None):
        if if_generation_match == 0 and self._path.exists():
            raise PreconditionFailed("destination already exists")
        self._path.parent.mkdir(parents=True, exist_ok=True)
        self._path.write_text(data)


class FakeOutBucket:
    def __init__(self, root):
        self.root = Path(root)
        self.metadata_by_name = {}

    def blob(self, name):
        return FakeOutBlob(self, name)

    def get_blob(self, name):
        blob = FakeOutBlob(self, name)
        if not blob.exists():
            return None
        blob.reload()
        return blob

    def copy_blob(self, blob, destination_bucket, new_name, if_generation_match=None):
        destination = destination_bucket.blob(new_name)
        if if_generation_match == 0 and destination.exists():
            raise PreconditionFailed("destination already exists")
        destination._path.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(blob._path, destination._path)
        destination_bucket.metadata_by_name[new_name] = self.metadata_by_name.get(
            blob.name
        )
        return destination


class FakeClient:
    def __init__(self, blobs):
        self.blobs = blobs

    def list_blobs(self, bucket_name, prefix):
        return [blob for blob in self.blobs if blob.name.startswith(prefix)]


class PoisonClient(FakeClient):
    def list_blobs(self, bucket_name, prefix):
        raise AssertionError("archived hour must not touch the source at all")


class FlakyClient(FakeClient):
    def list_blobs(self, bucket_name, prefix):
        if f"hour={DT}T11" in prefix:
            raise ConnectionError("simulated listing failure")
        return super().list_blobs(bucket_name, prefix)


class TestGtfsRtCompactor:
    @pytest.fixture
    def source_blobs(self):
        blobs = []
        for i in range(40):
            path = (
                f"{FEED_TYPE}/dt={DT}/hour={HOUR_ISO}/"
                f"ts={DT}T{HOUR:02d}:{i:02d}:20+00:00/base64_url=dGVzdA==/feed"
            )
            data = hashlib.sha256(str(i).encode()).digest() * (i + 1)
            metadata = json.dumps({"filename": "feed", "ts": f"{i}"})
            blobs.append(
                FakeBlob(
                    path,
                    data,
                    {compactor.PARTITIONED_ARTIFACT_METADATA_KEY: metadata},
                )
            )
        return blobs

    def compact_hour(self, client, bucket, hour=HOUR):
        return compactor.HourCompaction(
            client=client,
            raw_bucket_name="raw-bucket",
            compacted_bucket=bucket,
            feed_type=FEED_TYPE,
            dt=DT,
            hour=hour,
            workers=4,
            chunk_size=16,
        ).compact()

    def day_compaction(self, client, bucket, hours):
        return compactor.DayCompaction(
            client=client,
            raw_bucket_name="raw-bucket",
            compacted_bucket=bucket,
            feed_type=FEED_TYPE,
            dt=DT,
            hours=hours,
            workers=4,
            chunk_size=16,
        )

    def test_happy_path_roundtrip(self, tmp_path, source_blobs):
        bucket = FakeOutBucket(tmp_path)
        outcome = self.compact_hour(FakeClient(source_blobs), bucket)

        assert outcome.written_rows == len(source_blobs)
        assert outcome.parquet_path == FINAL_NAME
        assert not (tmp_path / TMP_NAME).exists()

        recorded = json.loads(
            bucket.metadata_by_name[FINAL_NAME][
                compactor.PARTITIONED_ARTIFACT_METADATA_KEY
            ]
        )
        assert recorded["written_rows"] == len(source_blobs)
        assert recorded["listed_bytes"] == sum(b.size for b in source_blobs)

        table = pq.read_table(tmp_path / FINAL_NAME)
        assert table.num_rows == len(source_blobs)
        rows = {row["path"]: row for row in table.to_pylist()}
        for blob in source_blobs:
            assert rows[blob.name]["data"] == blob.data
            assert (
                rows[blob.name]["metadata"]
                == blob.metadata[compactor.PARTITIONED_ARTIFACT_METADATA_KEY]
            )
            assert rows[blob.name]["base64_url"] == "dGVzdA=="

    def test_rerun_skips_published_hour(self, tmp_path, source_blobs):
        bucket = FakeOutBucket(tmp_path)
        first = self.compact_hour(FakeClient(source_blobs), bucket)
        before = (tmp_path / FINAL_NAME).read_bytes()

        # The rerun must not list or download anything: PoisonClient raises on
        # any source access, covering both decayed sources and late arrivals.
        rerun = self.compact_hour(PoisonClient([]), bucket)

        assert rerun.written_rows == first.written_rows
        assert rerun.listed_objects == first.listed_objects
        assert rerun.parquet_path == FINAL_NAME
        assert (tmp_path / FINAL_NAME).read_bytes() == before

    def test_failed_first_run_leaves_nothing(self, tmp_path, source_blobs):
        bucket = FakeOutBucket(tmp_path)
        source_blobs[20].fail = True

        with pytest.raises(ConnectionError):
            self.compact_hour(FakeClient(source_blobs), bucket)

        assert not (tmp_path / FINAL_NAME).exists()
        assert not (tmp_path / TMP_NAME).exists()
        assert FINAL_NAME not in bucket.metadata_by_name

    def test_empty_hour_skips(self, tmp_path):
        outcome = self.compact_hour(FakeClient([]), FakeOutBucket(tmp_path))

        assert outcome.listed_objects == 0
        assert outcome.written_rows == 0
        assert not (tmp_path / FINAL_NAME).exists()

    def test_foreign_file_without_metadata_refuses(self, tmp_path, source_blobs):
        bucket = FakeOutBucket(tmp_path)
        foreign = tmp_path / FINAL_NAME
        foreign.parent.mkdir(parents=True, exist_ok=True)
        foreign.write_bytes(b"not ours")

        with pytest.raises(RuntimeError, match="delete it deliberately"):
            self.compact_hour(FakeClient(source_blobs), bucket)

        assert foreign.read_bytes() == b"not ours"

    def test_lost_publish_race_keeps_winner(self, tmp_path, source_blobs):
        rival_stats = {
            "hour": HOUR_ISO,
            "listed_objects": 7,
            "listed_bytes": 700,
            "written_rows": 7,
        }

        class RaceBucket(FakeOutBucket):
            def copy_blob(
                self, blob, destination_bucket, new_name, if_generation_match=None
            ):
                # A rival writer publishes between our staging and our copy.
                if new_name == FINAL_NAME and not (self.root / FINAL_NAME).exists():
                    rival = self.blob(FINAL_NAME)
                    rival._path.parent.mkdir(parents=True, exist_ok=True)
                    rival._path.write_bytes(b"rival parquet")
                    self.metadata_by_name[FINAL_NAME] = {
                        compactor.PARTITIONED_ARTIFACT_METADATA_KEY: json.dumps(
                            rival_stats
                        )
                    }
                return super().copy_blob(
                    blob, destination_bucket, new_name, if_generation_match
                )

        bucket = RaceBucket(tmp_path)
        outcome = self.compact_hour(FakeClient(source_blobs), bucket)

        assert outcome.written_rows == 7
        assert (tmp_path / FINAL_NAME).read_bytes() == b"rival parquet"
        assert not (tmp_path / TMP_NAME).exists()

    def test_day_captures_failures(self, tmp_path, source_blobs):
        bucket = FakeOutBucket(tmp_path)
        day = self.day_compaction(FlakyClient(source_blobs), bucket, [HOUR, 11])
        outcomes = day.outcomes()

        assert outcomes[0].success
        assert outcomes[0].written_rows == len(source_blobs)
        assert not outcomes[1].success
        assert "simulated" in str(outcomes[1].exception)
        assert day.failed_hours() == [outcomes[1].hour]
        assert (tmp_path / FINAL_NAME).exists()

        row = json.loads(outcomes[1].json())
        assert row["success"] is False
        assert row["exception"]

    def test_day_retry_skips_published_hours(self, tmp_path, source_blobs):
        bucket = FakeOutBucket(tmp_path)
        self.day_compaction(FakeClient(source_blobs), bucket, [HOUR]).outcomes()

        # The retry sees the published hour and never touches the source; the
        # manifest is built from the stats recorded at publish time.
        retry = self.day_compaction(PoisonClient([]), bucket, [HOUR])
        manifest = retry.write_manifest()

        assert retry.failed_hours() == []
        assert manifest["written_rows"] == len(source_blobs)
        on_disk = json.loads((tmp_path / MANIFEST_NAME).read_text())
        assert on_disk == json.loads(json.dumps(manifest))
        assert on_disk["hours"][0]["parquet_path"] == FINAL_NAME

    def test_manifest_written_once(self, tmp_path, source_blobs):
        bucket = FakeOutBucket(tmp_path)
        self.day_compaction(FakeClient(source_blobs), bucket, [HOUR]).write_manifest()
        before = (tmp_path / MANIFEST_NAME).read_bytes()

        self.day_compaction(FakeClient(source_blobs), bucket, [HOUR]).write_manifest()

        assert (tmp_path / MANIFEST_NAME).read_bytes() == before

    def test_refuses_incomplete_partition(self, monkeypatch):
        monkeypatch.setenv("CALITP_BUCKET__GTFS_RT_RAW", "gs://raw")
        monkeypatch.setenv("CALITP_BUCKET__GTFS_RT_RAW_COMPACTED", "gs://compacted")
        monkeypatch.setenv("CALITP_BUCKET__GTFS_RT_PARSED", "gs://parsed")
        today = datetime.date.today().isoformat()

        result = CliRunner().invoke(compactor.app, [FEED_TYPE, today])

        assert result.exit_code != 0
        assert "not fully in the past" in str(result.exception)

    def test_outcomes_artifact_path(self, monkeypatch):
        monkeypatch.setattr(compactor, "COMPACTION_OUTCOMES_BUCKET", "parsed-bucket")
        result = compactor.GTFSRTCompactionJobResult(
            filename="results.jsonl",
            feed_type=compactor.GTFSFeedType(FEED_TYPE),
            dt=compactor.pendulum.parse(DT).date(),
            outcomes=[],
        )

        assert result.path == (
            f"parsed-bucket/{FEED_TYPE}_compaction_outcomes/dt={DT}/results.jsonl"
        )
