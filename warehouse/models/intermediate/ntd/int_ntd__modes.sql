{{
    config(
        materialized='table',
    )
}}

WITH int_ntd__modes as (
    SELECT * FROM {{ ref('ntd_modes_to_full_names') }}
)
SELECT * FROM int_ntd__modes
