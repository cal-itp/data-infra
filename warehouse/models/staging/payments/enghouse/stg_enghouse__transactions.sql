WITH source AS (
    SELECT * FROM {{ source('external_enghouse', 'transactions') }}
),

clean_columns AS (
    SELECT
        SAFE_CAST(OperatorId AS INT64) AS operator_id,
        {{ trim_make_empty_string_null('id') }} AS id,
        {{ trim_make_empty_string_null('operation') }} AS operation,
        SAFE_CAST(terminal_id AS INT64) AS terminal_id,
        {{ trim_make_empty_string_null('mapping_terminal_id') }} AS mapping_terminal_id,
        {{ trim_make_empty_string_null('mapping_merchant_id') }} AS mapping_merchant_id,
        SAFE_CAST(timestamp AS TIMESTAMP) AS timestamp,
        SAFE_CAST(amount AS NUMERIC) AS amount,
        {{ trim_make_empty_string_null('payment_reference') }} AS payment_reference,
        SAFE_CAST(spdh_response AS INT64) AS spdh_response,
        {{ trim_make_empty_string_null('response_type') }} AS response_type,
        {{ trim_make_empty_string_null('response_message') }} AS response_message,
        {{ trim_make_empty_string_null('token') }} AS token,
        {{ trim_make_empty_string_null('issuer_response') }} AS issuer_response,
        SAFE_CAST(core_response AS INT64) AS core_response,
        SAFE_CAST(rrn AS INT64) AS rrn,
        {{ trim_make_empty_string_null('authorization_code') }} AS authorization_code,
        {{ trim_make_empty_string_null('par') }} AS par,
        {{ trim_make_empty_string_null('brand') }} AS brand,
        {{ dbt_utils.generate_surrogate_key(['OperatorId', 'id', 'operation', 'terminal_id', 'mapping_terminal_id', 'mapping_merchant_id',
            'timestamp', 'amount', 'payment_reference', 'spdh_response', 'response_type', 'response_message', 'token', 'issuer_response',
            'core_response', 'rrn', 'authorization_code', 'par', 'brand']) }} AS _content_hash
    FROM source
),

stg_enghouse__transactions AS (
    SELECT
        operator_id,
        id,
        operation,
        terminal_id,
        mapping_terminal_id,
        mapping_merchant_id,
        timestamp,
        amount,
        payment_reference,
        spdh_response,
        response_type,
        response_message,
        token,
        issuer_response,
        core_response,
        rrn,
        authorization_code,
        par,
        brand,
        _content_hash
    FROM clean_columns
)

SELECT * FROM stg_enghouse__transactions
