# ---
# dependencies:
#   - op_external_table
#   - merge_create_merge_target
# ---

from calitp import get_engine
from calitp.config import get_bucket

from merge_sql import SQL_TEMPLATE

merges = [
    {
        "target": "sandbox.merge_target",
        "source": "sandbox.external_table",
        "bucket_like_str": f"{get_bucket()}/sandbox/external_table_1.csv",
        "execution_date": "2021-01-01",
    },
    {
        "target": "sandbox.merge_target",
        "source": "sandbox.external_table",
        "bucket_like_str": f"{get_bucket()}/sandbox/external_table_2.csv",
        "execution_date": "2021-01-02",
    },
    {
        "target": "sandbox.merge_target",
        "source": "sandbox.external_table",
        "bucket_like_str": f"{get_bucket()}/sandbox/external_table_3.csv",
        "execution_date": "2021-01-03",
    },
]

engine = get_engine()

for entry in merges:
    sql_code = SQL_TEMPLATE.format(**entry)
    engine.execute(sql_code)
