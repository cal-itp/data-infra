WITH source AS (
    SELECT * FROM {{ source('external_littlepay', 'customer_funding_source') }}
),

stg_littlepay__customer_funding_source AS (
    SELECT
        funding_source_id,
        funding_source_vault_id,
        customer_id,
        bin,
        masked_pan,
        card_scheme,
        issuer,
        issuer_country,
        form_factor,
        principal_customer_id,
        _line_number,
        `instance`,
        extract_filename,
        ts,
        DENSE_RANK() OVER (
            PARTITION BY funding_source_id
            ORDER BY ts DESC) AS calitp_funding_source_id_rank,
        DENSE_RANK() OVER (
            PARTITION BY funding_source_vault_id
            ORDER BY ts DESC) AS calitp_funding_source_vault_id_rank,
        DENSE_RANK() OVER (
            PARTITION BY customer_id
            ORDER BY ts DESC) AS calitp_customer_id_rank,
    FROM source
)

SELECT * FROM stg_littlepay__customer_funding_source
