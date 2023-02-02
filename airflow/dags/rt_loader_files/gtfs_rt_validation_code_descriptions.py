# ---
# operator: operators.PythonToWarehouseOperator
# table_name: "gtfs_rt.validation_code_descriptions"
# fields:
#   code: RT Validation error code name
#   description: A description of the validation error
#   is_critical: Whether this error is considered a Cal-ITP critical error
# ---

import pandas as pd
from calitp import to_snakecase, write_table

sheet_url = (
    "https://docs.google.com/spreadsheets"
    "/d/1GDDaDlsBPCYn3dtYPSABnce9ns3ekJ8Jzfgyy56lZz4/export?gid=617612870&format=csv"
)

code_descriptions = pd.read_csv(sheet_url).pipe(to_snakecase)

write_table(code_descriptions, "gtfs_rt.validation_code_descriptions")
