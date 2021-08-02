# ---
# dependencies:
#   - op_external_table
# ---

from calitp import get_table

get_table("sandbox.external_table", as_df=True)
