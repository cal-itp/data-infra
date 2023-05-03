{{ config(materialized='table') }}

WITH fct_benefits_events AS (
    SELECT * FROM {{ ref('stg_amplitude__benefits_events') }}
)

SELECT * FROM fct_benefits_events
