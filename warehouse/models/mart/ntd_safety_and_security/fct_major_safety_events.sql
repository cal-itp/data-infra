WITH staging_major_safety_events AS (
    SELECT *
    FROM {{ ref('stg_ntd__major_safety_events') }}
),

fct_major_safety_events AS (
    SELECT *
    FROM staging_major_safety_events
)

SELECT * FROM fct_major_safety_events
