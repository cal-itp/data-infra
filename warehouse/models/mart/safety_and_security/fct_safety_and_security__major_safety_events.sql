WITH staging_major_safety_events AS (
    SELECT *
    FROM {{ ref('stg_ntd__major_safety_events') }}
),

fct_safety_and_security__major_safety_events AS (
    SELECT *
    FROM staging_major_safety_events
)

SELECT * FROM fct_safety_and_security__major_safety_events
