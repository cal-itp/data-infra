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

filtered_transactions AS (
    SELECT
        *,
        CASE
            WHEN operation = 'REFUND' THEN 'CREDIT'
            ELSE 'DEBIT'
        END AS settlement_type,
    FROM transactions
    WHERE operation in ('DEBT_RECOVERY_AUTO', 'ONLINE_CLEARING', 'DEBT_RECOVERY_MANUAL', 'PREAUTH_FINAL', 'REFUND')
),

stg_enghouse__deduped_transactions AS (
    SELECT * FROM filtered_transactions
    -- Per operator_id + payment_reference, keep the most recent row of each settlement_type, so a
    -- CREDIT (refund) and a DEBIT (non-refund) for the same payment_reference are kept as separate
    -- rows. payment_reference is not unique between operators. Rows with a null payment_reference
    -- cannot be deduplicated this way, so they are all retained.
    QUALIFY
        ROW_NUMBER() OVER (
            PARTITION BY operator_id, payment_reference, settlement_type
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
    settlement_type,
    agency,
    dt,
    _payments_key,
    _content_hash
FROM stg_enghouse__deduped_transactions
