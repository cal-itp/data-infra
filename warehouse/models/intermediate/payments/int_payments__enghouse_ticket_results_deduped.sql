{{ config(materialized = 'table') }}

WITH ticket_results AS (
    SELECT * FROM {{ ref('stg_enghouse__ticket_results') }}
),

deduplicated AS (
    SELECT * FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (
                PARTITION BY _content_hash
                ORDER BY
                    CASE WHEN start_dttm IS NOT NULL THEN 0 ELSE 1 END ASC,
                    CASE WHEN end_dttm IS NOT NULL THEN 0 ELSE 1 END ASC,
                    CASE WHEN created_dttm IS NOT NULL THEN 0 ELSE 1 END ASC
            ) AS row_num
        FROM ticket_results
    )
    WHERE row_num = 1
),

int_payments__enghouse_ticket_results_deduped AS (
    SELECT
        operator_id,
        id,
        ticket_id,
        station_name,
        amount,
        clearing_id,
        reason,
        tap_id,
        ticket_type,
        created_dttm,
        line,
        start_station,
        end_station,
        start_dttm,
        end_dttm,
        ticket_code,
        additional_infos,
        _content_hash
    FROM deduplicated
)

SELECT * FROM int_payments__enghouse_ticket_results_deduped
