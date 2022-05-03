{{ config(materialized='table') }}

WITH stg_enriched_device_transaction_purchases AS (
    {{
        sql_enrich_duplicates(
            source('payments', 'device_transactions'),
            ['littlepay_transaction_id'],
            ['calitp_file_name desc', 'transaction_date_time_utc desc']
        )
    }}
)

SELECT
    *,
    DATETIME(TIMESTAMP(transaction_date_time_utc), "America/Los_Angeles") AS transaction_date_time_pacific,
FROM stg_enriched_device_transaction_purchases
