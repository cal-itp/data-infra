# ---
# python_callable: process_elavon_data_to_jsonl
# provide_context: true
# ---
# To run locally:
#   PYTHONPATH=[local fully qualified path to repo root]/airflow/plugins uv run elavon_to_gcs_jsonl.py
#
import gzip
import io
import json
import logging
import os
import zipfile
from typing import ClassVar, List, Optional

import pandas as pd
import pendulum
from calitp_data_infra.storage import (  # type: ignore
    PartitionedGCSArtifact,
    get_fs,
    make_name_bq_safe,
)

CALITP_BUCKET__ELAVON_RAW = os.environ["CALITP_BUCKET__ELAVON_RAW"]
CALITP_BUCKET__ELAVON_PARSED = os.environ["CALITP_BUCKET__ELAVON_PARSED"]

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s %(message)s",
    handlers=[
        logging.FileHandler("elavon_to_gcs_jsonl.log", mode="w"),
        logging.StreamHandler(),
    ],
)
logger = logging.getLogger(__name__)


class ElavonExtract(PartitionedGCSArtifact):
    bucket: ClassVar[str] = CALITP_BUCKET__ELAVON_PARSED
    table: ClassVar[str] = "transactions"
    execution_ts: pendulum.DateTime = pendulum.now()
    dt: pendulum.Date = execution_ts.date()
    partition_names: ClassVar[List[str]] = ["dt", "execution_ts"]
    data: Optional[pd.DataFrame]

    class Config:
        arbitrary_types_allowed = True

    def save_to_gcs(self, fs):
        self.save_content(
            fs=fs,
            content=gzip.compress(
                self.data.to_json(
                    orient="records", lines=True, default_handler=str
                ).encode()
            ),
            exclude={"data"},
        )


def get_audit_data(fs, path):
    """Get GCS object metadata for the parsing audit record."""
    info = fs.info(path)
    return {
        "agency": None,
        "filename": os.path.basename(path),
        "path": path.removeprefix("gs://").split("/", 1)[-1],
        "ts": info["mtime"].isoformat(),
        "size": info["size"],
    }


def process_elavon_data_to_jsonl():
    fs = get_fs()

    # List raw files available from GCS
    file_and_dir_list = fs.ls(f"{CALITP_BUCKET__ELAVON_RAW}/", detail=False)
    file_list = [x for x in file_and_dir_list if fs.isfile(x) and x.endswith(".zip")]

    if not file_list:
        logger.warning("No extracts were found in GCS")
        return

    logger.info(f"Found {len(file_list)} zip files to process")

    execution_ts = pendulum.now()
    for file in file_list:
        logger.info(f"Processing file {file}")

        buf = io.BytesIO(fs.cat(file))
        with zipfile.ZipFile(buf) as zf:
            inner = zf.namelist()[0]
            with zf.open(inner) as f:
                df = pd.read_csv(f, delimiter="|", dtype=str)
        cleaned_df = df.rename(make_name_bq_safe, axis="columns")

        filename = file.split("/")[-1].rsplit(".", 1)[0] + ".jsonl.gz"
        extract = ElavonExtract(filename=filename, execution_ts=execution_ts)
        extract.data = cleaned_df

        logger.info(f"Saving {filename} with {len(cleaned_df)} rows")
        extract.save_to_gcs(fs=fs)

        # Record metadata for the raw and successfully parsed files.
        raw_audit_data = get_audit_data(fs, file)
        parsed_audit_data = get_audit_data(fs, extract.path)

        audit_path = (
            f"{CALITP_BUCKET__ELAVON_PARSED}/"
            "elavon_parse_job_results/"
            + "/".join(extract.serialized_partitions)
            + f"/{os.path.splitext(filename)[0]}.jsonl"
        )

        fs.pipe(
            path=audit_path,
            value=json.dumps(
                {"raw": raw_audit_data, "parsed": parsed_audit_data},
                separators=(",", ":"),
                default=str,
            ).encode(),
        )
        logger.info("Saved audit record to %s", audit_path)


if __name__ == "__main__":
    process_elavon_data_to_jsonl()
