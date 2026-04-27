{{ config(materialized = 'table') }}

WITH ticket_results AS (
    SELECT * FROM {{ ref('stg_enghouse__ticket_results') }}
),

int_payments__enghouse_ticket_results_deduped AS (
    SELECT
        operator_id,
        id,
        ticket_id,
        station_name,
        amount,
        reason,
        tap_id,
        ticket_type,
        line,
        start_station,
        end_station,
        ticket_code,
        additional_infos,
        _content_hash,
        MIN(clearing_id) AS clearing_id,
        MIN(created_dttm) AS created_dttm,
        MIN(start_dttm) AS start_dttm,
        MIN(end_dttm) AS end_dttm
    FROM ticket_results
    {{ dbt_utils.group_by(n=14) }}
)

SELECT * FROM int_payments__enghouse_ticket_results_deduped
