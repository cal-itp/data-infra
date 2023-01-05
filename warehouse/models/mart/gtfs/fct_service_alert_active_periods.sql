WITH messages AS (
    SELECT *
    FROM {{ ref('fct_service_alerts_messages') }}
),

fct_service_alerts_active_periods AS (
    SELECT
        key AS service_alert_message_key,
        {{ dbt_utils.surrogate_key(['key', 'unnested_active_period.start', 'unnested_active_period.end']) }} AS key,
        unnested_active_period.start AS active_period_start,
        unnested_active_period.end AS active_period_end,
    FROM messages
    -- https://stackoverflow.com/questions/44918108/google-bigquery-i-lost-null-row-when-using-unnest-function
    -- these arrays have nulls
    LEFT JOIN UNNEST(messages.active_period) AS unnested_active_period
)

SELECT * FROM fct_service_alerts_active_periods
