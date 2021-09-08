# ---
# dependencies:
#   - merge_run
# ---

import pprint

from calitp import get_table

df = get_table("sandbox.merge_target", as_df=True)
pprint.pprint(
    df.sort_values(["calitp_extracted_at", "calitp_deleted_at"]).to_dict(
        orient="records"
    )
)
