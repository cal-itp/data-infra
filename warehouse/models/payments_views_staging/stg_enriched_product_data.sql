{{ config(materialized='table') }}

WITH stg_enriched_product_data AS (
    {{
        sql_enrich_duplicates(
            source('payments', 'product_data'),
            ['product_id'],
            ['calitp_file_name desc']
        )
    }}
)

SELECT * FROM stg_enriched_product_data
