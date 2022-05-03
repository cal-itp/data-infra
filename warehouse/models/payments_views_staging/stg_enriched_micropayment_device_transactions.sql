{{ config(materialized='table') }}

WITH stg_enriched_micropayment_device_transactions AS (
    {{
        sql_enrich_duplicates(
            source('payments', 'micropayment_device_transactions'),
            ['calitp_hash'],
            ['calitp_file_name desc']
        )
    }}
)

SELECT * FROM stg_enriched_micropayment_device_transactions
