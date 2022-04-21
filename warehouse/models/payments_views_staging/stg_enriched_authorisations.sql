{{ config(materialized='table') }}

WITH stg_enriched_authorisations AS (
    {{
        sql_enrich_duplicates(
            source('payments', 'authorisations'),
            ['calitp_hash'],
            ['calitp_file_name desc']
        )
    }}
)

SELECT * FROM stg_enriched_authorisations
