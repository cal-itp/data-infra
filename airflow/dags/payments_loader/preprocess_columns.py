# ---
# python_callable: main
# provide_context: true
# dependencies:
#   - calitp_included_payments_tables
# ---


from calitp.config import get_bucket
from calitp.storage import get_fs
from calitp.sql import get_table
from utils import _keep_columns

DATASET = "payments"

SRC_DIR = "gs://littlepay-data-extract-prod/mst/{table_name}/{date_string_narrow}*.psv"
STAGE_DIR = "mst/{table_name}"
DST_DIR = "mst/processed/{table_name}"


def main(execution_date, **kwargs):

    fs = get_fs()

    # Get high level data on tables we are pre-processing
    tables = get_table("payments.calitp_included_payments_tables", as_df=True)
    schemas = [get_table(f"{DATASET}.{t}").columns.keys() for t in tables.table_name]

    # We'll save date in YYYY-MM-DD format, but littlepay uses YYYYMMDD
    # so we keep the original format for globbing all of the data files for a
    # specific day
    date_string = execution_date.to_date_string()
    date_string_narrow = date_string.replace("-", "")

    for table_name, columns in zip(tables.table_name, schemas):
        stg_dir = STAGE_DIR.format(table_name=table_name)
        dst_dir = DST_DIR.format(table_name=table_name)
        src_files = fs.glob(
            SRC_DIR.format(
                table_name=table_name.replace("_", "-"),
                date_string_narrow=date_string_narrow,
            )
        )

        print(f"\n\nTable {table_name} has {len(src_files)} new files =========")

        for fname in src_files:
            basename = fname.split("/")[-1]

            stg_fname = f"{stg_dir}/{basename}"
            dst_fname = f"{dst_dir}/{date_string}_{basename}"

            print(f"copying from payments bucket: {stg_fname} -> {dst_fname}")
            fs.cp(fname, f"{get_bucket()}/{stg_fname}")

            _keep_columns(
                stg_fname,
                dst_fname,
                colnames=columns,
                extracted_at=date_string,
                delimiter="|",
            )
