WITH staging_fra_regulated_mode_major_security_events AS (
    SELECT *
    FROM {{ ref('stg_ntd_safety_and_security__fra_regulated_mode_major_security_events') }}
),

fct_safety_and_security__fra_regulated_mode_major_security_events AS (
    SELECT *
    FROM staging_fra_regulated_mode_major_security_events
)

SELECT * FROM fct_safety_and_security__fra_regulated_mode_major_security_events
