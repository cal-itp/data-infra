{{ config(materialized = "table") }}

WITH authorisations_v1 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__authorisations') }}
    -- For agencies that had v1 feeds, keep everything before cutover date
    WHERE littlepay_export_date <= '2025-05-16'
),

authorisations_v3 AS (
    SELECT *
    FROM {{ ref('stg_littlepay__authorisations_v3') }}
    WHERE
        -- Keep all records for Nevada County Connects and SacRT, these agencies didn't have a competing feed v1 so we keep it all
        participant_id IN ('nevada-county-connects', 'sacrt')

        -- For the following participants only, keep records including and after 5/17/2025 (cutover date for agencies that had both feeds at some point)
        OR (
            participant_id NOT IN ('nevada-county-connects', 'sacrt')
            AND littlepay_export_date >= '2025-05-17'
        )
),

int_littlepay__unioned_authorisations AS (
    SELECT *
    FROM authorisations_v1
    UNION ALL
    SELECT * FROM authorisations_v3
)

SELECT * FROM int_littlepay__unioned_authorisations
