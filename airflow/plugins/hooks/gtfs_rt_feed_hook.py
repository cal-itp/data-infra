import json
import os

from google.protobuf import json_format
from google.transit import gtfs_realtime_pb2
from src.bigquery_cleaner import BigQueryRowCleaner


class GTFSRTFeedParseResult:
    def __init__(
        self,
        metadata: dict,
        object_name: str,
        parsed: dict[any] = None,
        exception: Exception = None,
    ) -> None:
        self.metadata: dict = metadata
        self.object_name: str = object_name
        self.parsed: dict[any] = parsed
        self.exception: Exception = exception
        self.first_extract: dict[any] = None

    def set_first_extract(self, first_extract: dict[any]) -> None:
        self.first_extract = first_extract

    def parsed_metadata(self) -> dict:
        return BigQueryRowCleaner(
            json.loads(self.metadata["PARTITIONED_ARTIFACT_METADATA"])
        ).clean()

    def results(self, first_extract: dict) -> dict:
        return BigQueryRowCleaner(
            {
                "step": "parse",
                "success": self.exception is None,
                "header": BigQueryRowCleaner(self.parsed["header"]).clean()
                if self.parsed and "header" in self.parsed
                else None,
                "exception": str(self.exception) if self.exception else None,
                "blob_path": None if self.exception is None else self.object_name,
                "aggregation": {
                    "step": "parse",
                    "filename": os.path.basename(self.object_name),
                    "first_extract": first_extract,
                },
                "extract": self.parsed_metadata(),
                "process_stderr": None,
            },
            preserve_nones=True,
        ).clean()

    def entities(self) -> list[dict]:
        return [
            {
                "header": self.parsed["header"],
                "metadata": {
                    "extract_ts": self.parsed_metadata()["ts"],
                    "extract_config": self.parsed_metadata()["config"],
                },
                **entity,
            }
            for entity in self.parsed["entity"]
        ]


class GTFSRTFeedHook:
    def parse(
        self, object_name: str, source: bytes, metadata: dict
    ) -> GTFSRTFeedParseResult:
        options: dict = {
            "object_name": object_name,
            "metadata": metadata,
        }
        try:
            feed: gtfs_realtime_pb2.FeedMessage = gtfs_realtime_pb2.FeedMessage()
            feed.ParseFromString(source)
            parsed: dict[any] = json_format.MessageToDict(feed)
            return GTFSRTFeedParseResult(parsed=parsed, **options)
        except Exception as e:
            return GTFSRTFeedParseResult(exception=e, **options)
