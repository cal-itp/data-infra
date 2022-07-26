WITH stg_enriched_settlements AS (
    {{
        sql_enrich_duplicates(
            source('payments', 'settlements'),
            ['settlement_id'],
            ['calitp_file_name desc']
        )
    }}
)

SELECT * FROM stg_enriched_settlements
