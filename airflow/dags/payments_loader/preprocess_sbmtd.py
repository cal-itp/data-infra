# ---
# python_callable: main
# provide_context: true
# dependencies:
#   - calitp_included_payments_tables
# ---


from libs.littlepay import preprocess_littlepay_provider_bucket


def main(execution_date, **kwargs):
    preprocess_littlepay_provider_bucket(execution_date, provider_name="sbmtd")
