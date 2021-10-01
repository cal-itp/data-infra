from calitp.config import get_bucket
from calitp.storage import get_fs
from calitp.sql import get_table
from utils import _keep_columns

DATASET = "payments"

# Currently, the littlepay data is small enough that we can fully ingest
# and re-process daily. Ideally, as the data grows, we work with the
# provider to remove the need to do pre-processing of their data, and
# can load it directly in to bigquery.
# However, if we move to processing only the data for a given day each task,
# we should change the SRC_DIR glob to use a datetime

DEFAULT_SRC_URL_TEMPLATE = (
    "gs://littlepay-data-extract-prod/{aws_user}/{aws_user}/{table_name}/*.psv"
)
DEFAULT_STG_DIR_TEMPLATE = "payments-staging/{table_name}"
DEFAULT_DST_DIR_TEMPLATE = "payments-processed/{table_name}"


def preprocess_littlepay_provider_bucket(
    execution_date,
    aws_user,
    src_url_template=DEFAULT_SRC_URL_TEMPLATE,
    stg_dir_template=DEFAULT_STG_DIR_TEMPLATE,
    dst_dir_template=DEFAULT_DST_DIR_TEMPLATE,
):
    fs = get_fs()

    # Get high level data on tables we are pre-processing ----
    tables = get_table("payments.calitp_included_payments_tables", as_df=True)
    schemas = [get_table(f"{DATASET}.{t}").columns.keys() for t in tables.table_name]

    # We'll save date in YYYY-MM-DD format, but littlepay uses YYYYMMDD
    # so we keep the original format for globbing all of the data files for a
    # specific day
    date_string = execution_date.to_date_string()
    date_string_narrow = date_string.replace("-", "")

    # process data for each table ----

    for table_name, columns in zip(tables.table_name, schemas):
        stg_dir = stg_dir_template.format(aws_user=aws_user, table_name=table_name)
        dst_dir = dst_dir_template.format(aws_user=aws_user, table_name=table_name)
        src_files = fs.glob(
            src_url_template.format(
                aws_user=aws_user,
                table_name=table_name.replace("_", "-"),
                date_string_narrow=date_string_narrow,
            )
        )

        print(f"\n\nTable {table_name} has {len(src_files)} new files =========")

        # remove previously processed data, in case they remove any data files ---

        dst_old_url = f"{get_bucket()}/{dst_dir}/*_{aws_user}_*"
        dst_old_files = fs.glob(dst_old_url)

        if dst_old_files:
            print(
                f"Deleting {len(dst_old_files)} old file(s) for "
                f"{aws_user} {table_name}."
            )
            fs.rm(dst_old_files)

        # copy and process each file ----

        for fname in src_files:
            basename = fname.split("/")[-1]

            stg_fname = f"{stg_dir}/{aws_user}_{basename}"
            dst_fname = f"{dst_dir}/{date_string}_{aws_user}_{basename}"

            print(f"copying from payments bucket: {stg_fname} -> {dst_fname}")
            fs.cp(fname, f"{get_bucket()}/{stg_fname}")

            _keep_columns(
                stg_fname,
                dst_fname,
                colnames=columns,
                extracted_at=date_string,
                delimiter="|",
            )
