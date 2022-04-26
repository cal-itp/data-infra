{{ config(materialized='table') }}

WITH stg_enriched_device_transaction_purchases AS (
    {{
        sql_enrich_duplicates(
            source('payments', 'device_transaction_purchases'),
            ['purchase_id'],
            ['calitp_file_name desc']
        )
    }}
)

SELECT * FROM stg_enriched_device_transaction_purchases
