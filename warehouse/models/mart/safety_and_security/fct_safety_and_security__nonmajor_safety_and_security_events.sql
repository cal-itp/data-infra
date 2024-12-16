WITH staging_nonmajor_safety_and_security_events AS (
    SELECT *
    FROM {{ ref('stg_ntd__nonmajor_safety_and_security_events') }}
),

fct_safety_and_security__nonmajor_safety_and_security_events AS (
    SELECT *
    FROM staging_nonmajor_safety_and_security_events
)

SELECT * FROM fct_safety_and_security__nonmajor_safety_and_security_events
