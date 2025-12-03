import os
from datetime import datetime

from operators.ntd_xlsx_to_gcs_operator import NTDXLSXToGCSOperator
from operators.ntd_xlsx_to_jsonl_operator import NTDXLSXToJSONLOperator

from airflow import DAG
from airflow.operators.latest_only import LatestOnlyOperator

NTD_PRODUCTS = [
    {
        "type": "annual_database_agency_information",
        "short_type": "_2022_agency_information",
        "year": 2022,
        "url": "https://www.transit.dot.gov/ntd/data-product/2022-annual-database-agency-information",
    },
]

with DAG(
    dag_id="download_and_parse_ntd_xlsx",
    # Every day at midnight
    schedule="0 0 * * *",
    start_date=datetime(2025, 11, 1),
    catchup=False,
    tags=["ntd"],
):
    latest_only = LatestOnlyOperator(task_id="latest_only", depends_on_past=False)

    for ntd_product in NTD_PRODUCTS:
        download_xlsx = NTDXLSXToGCSOperator(
            task_id="ntd_xlsx_to_gcs",
            source_url=ntd_product["url"],
            source_bucket=os.environ.get("CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__RAW"),
            source_path=os.path.join(
                f"{ntd_product['type']}_raw",
                f"{ntd_product['year']}",
                "dt={{ dt }}",
                "execution_ts={{ ts }}",
                f"{ntd_product['year']}__{ntd_product['type']}_raw.xlsx",
            ),
        )

        parse_xlsx = NTDXLSXToJSONLOperator(
            task_id="ntd_xlsx_to_jsonl",
            source_bucket=os.environ.get("CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__RAW"),
            source_path=os.path.join(
                f"{ntd_product['type']}_raw",
                f"{ntd_product['year']}",
                "dt={{ dt }}",
                "execution_ts={{ ts }}",
                f"{ntd_product['year']}__{ntd_product['type']}_raw.xlsx",
            ),
            destination_bucket=os.environ.get(
                "CALITP_BUCKET__NTD_XLSX_DATA_PRODUCTS__CLEAN"
            ),
            destination_path=os.path.join(
                f"{ntd_product['type']}",
                f"{ntd_product['year']}",
                f"{ntd_product['short_type']}",
                "dt={{ dt }}",
                "execution_ts={{ ts }}",
                f"{ntd_product['year']}__{ntd_product['type']}__{ntd_product['short_type']}.jsonl.gz",
            ),
        )

        latest_only >> download_xlsx >> parse_xlsx
