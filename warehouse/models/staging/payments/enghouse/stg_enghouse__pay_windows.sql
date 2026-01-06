WITH source AS (
    SELECT * FROM {{ source('external_enghouse', 'pay_windows') }}
),

clean_columns AS (
    SELECT
        SAFE_CAST(Operator_Id AS INT64) AS operator_id,
        {{ trim_make_empty_string_null('id') }} AS id,
        {{ trim_make_empty_string_null('token') }} AS token,
        SAFE_CAST(amount_settled AS NUMERIC) AS amount_settled,
        SAFE_CAST(amount_to_settle AS NUMERIC) AS amount_to_settle,
        SAFE_CAST(debt_settled AS NUMERIC) AS debt_settled,
        {{ trim_make_empty_string_null('stage') }} AS stage,
        {{ trim_make_empty_string_null('Payment_reference') }} AS payment_reference,
        SAFE_CAST(terminal_id AS INT64) AS terminal_id,
        SAFE_CAST(open_date AS TIMESTAMP) AS open_date,
        SAFE_CAST(close_date AS TIMESTAMP) AS close_date,
        {{ dbt_utils.generate_surrogate_key(['Operator_Id', 'id', 'token', 'amount_settled', 'amount_to_settle',
            'debt_settled', 'stage', 'Payment_reference', 'terminal_id', 'open_date', 'close_date']) }} AS _content_hash,
    FROM source
),

stg_enghouse__pay_windows AS (
    SELECT
        operator_id,
        id,
        token,
        amount_settled,
        amount_to_settle,
        debt_settled,
        stage,
        payment_reference,
        terminal_id,
        open_date,
        close_date,
        _content_hash,
    FROM clean_columns
)

SELECT * FROM stg_enghouse__pay_windows
