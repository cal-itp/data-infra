{{ config(materialized='table') }}

WITH stg_enriched_micropayment_adjustments AS (
    {{
        sql_enrich_duplicates(
            source('payments', 'micropayment_adjustments'),
            ['calitp_hash'],
            ['calitp_file_name desc']
        )
    }}
)

SELECT * FROM stg_enriched_micropayment_adjustments
