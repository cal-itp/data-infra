WITH transactions AS (
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
        agency,
        dt,
        _payments_key,
        _content_hash
    FROM {{ ref('stg_enghouse__transactions') }}
),

stg_enghouse__deduped_transactions AS (
    SELECT * FROM transactions
    -- Keep the most recent row per payment_reference. Rows with a null
    -- payment_reference cannot be deduplicated this way, so they are all retained.
    QUALIFY
        ROW_NUMBER() OVER (
            PARTITION BY payment_reference
            ORDER BY (timestamp IS NOT NULL) DESC, timestamp DESC, dt DESC
        ) = 1
        OR payment_reference IS NULL
)

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
    agency,
    dt,
    _payments_key,
    _content_hash
FROM stg_enghouse__deduped_transactions
