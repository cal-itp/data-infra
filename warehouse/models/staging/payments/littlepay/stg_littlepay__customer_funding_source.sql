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
    FROM source
)

SELECT * FROM stg_littlepay__customer_funding_source
