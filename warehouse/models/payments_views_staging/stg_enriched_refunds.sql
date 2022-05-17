{{ config(materialized='table') }}

WITH stg_enriched_refunds AS (
    {{
        sql_enrich_duplicates(
            source('payments', 'refunds'),
            ['refund_id'],
            ['calitp_file_name desc']
        )
    }}
)

SELECT * FROM stg_enriched_refunds
