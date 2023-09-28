WITH source AS (
    SELECT * FROM {{ littlepay_source('external_littlepay', 'customer_funding_source') }}
),

stg_littlepay__customer_funding_source AS (
    SELECT
        {{ trim_make_empty_string_null('funding_source_id') }} AS funding_source_id,
        {{ trim_make_empty_string_null('funding_source_vault_id') }} AS funding_source_vault_id,
        {{ trim_make_empty_string_null('customer_id') }} AS customer_id,
        {{ trim_make_empty_string_null('bin') }} AS bin,
        {{ trim_make_empty_string_null('masked_pan') }} AS masked_pan,
        {{ trim_make_empty_string_null('card_scheme') }} AS card_scheme,
        {{ trim_make_empty_string_null('issuer') }} AS issuer,
        {{ trim_make_empty_string_null('issuer_country') }} AS issuer_country,
        {{ trim_make_empty_string_null('form_factor') }} AS form_factor,
        {{ trim_make_empty_string_null('principal_customer_id') }} AS principal_customer_id,
        _line_number,
        `instance`,
        extract_filename,
        ts,
        littlepay_export_ts,
        -- flag in reverse order, since we usually want the latest
        DENSE_RANK() OVER (
            PARTITION BY funding_source_id
            ORDER BY littlepay_export_ts DESC) AS calitp_funding_source_id_rank,
        DENSE_RANK() OVER (
            PARTITION BY funding_source_vault_id
            ORDER BY littlepay_export_ts DESC) AS calitp_funding_source_vault_id_rank,
        DENSE_RANK() OVER (
            PARTITION BY customer_id
            ORDER BY littlepay_export_ts DESC) AS calitp_customer_id_rank,
    FROM source
)

SELECT * FROM stg_littlepay__customer_funding_source
