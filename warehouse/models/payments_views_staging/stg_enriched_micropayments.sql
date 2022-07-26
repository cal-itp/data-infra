WITH stg_enriched_micropayments AS (
    {{
        sql_enrich_duplicates(
            source('payments', 'micropayments'),
            ['micropayment_id'],
            ['calitp_file_name desc', 'transaction_time desc']
        )
    }}
)

SELECT * FROM stg_enriched_micropayments
