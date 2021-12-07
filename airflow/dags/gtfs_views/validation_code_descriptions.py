# ---
# operator: operators.PythonToWarehouseOperator
# table_name: "views.validation_code_descriptions"
# fields:
#   severity: Severity of the error code (e.g. validation_codes.severity)
#   code: Code name (e.g. validation_codes.code)
# ---

import pandas as pd
from calitp import write_table, to_snakecase

sheet_url = (
    "https://docs.google.com/spreadsheets"
    "/d/1GDDaDlsBPCYn3dtYPSABnce9ns3ekJ8Jzfgyy56lZz4/export?gid=0&format=csv"
)

code_descriptions = (
    pd.read_csv(sheet_url)
    .pipe(to_snakecase)
    .rename(columns={"type": "severity", "name": "code"})
)

code_descriptions["code"] = (
    code_descriptions.code.str.replace(r"(?<!^)(?=[A-Z])", "_")
    .str.lower()
    .str.replace("_notice$", "")
    .replace({"i_o_error": "io_error", "u_r_i_syntax_error": "uri_syntax_error"})
)

write_table(code_descriptions, "views.validation_code_descriptions")
