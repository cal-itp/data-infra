# ---
# python_callable: main
# dependencies:
#   - customer_funding_source
#   - device_transactions
#   - micropayment_adjustments
#   - micropayment_device_transactions
#   - micropayments
# ---

import pandas as pd
from calitp.config import get_project_id, format_table_name


# TODO: this could be data in the data folder
def main():
    df = pd.DataFrame(
        [
            # required tables ----
            ("customer_funding_source", ".psv"),
            ("device_transaction_purchases", ".psv"),
            ("device_transactions", ".psv"),
            ("micropayment_adjustments", ".psv"),
            ("micropayment_device_transactions", ".psv"),
            ("micropayments", ".psv"),
        ],
        columns=["table_name", "ext"],
    )

    df["file_name"] = df.table_name + df.ext

    df.to_gbq(
        format_table_name("payments.calitp_included_payments_tables"),
        project_id=get_project_id(),
        if_exists="replace",
    )
