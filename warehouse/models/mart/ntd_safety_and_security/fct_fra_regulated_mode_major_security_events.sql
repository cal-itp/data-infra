WITH staging_fra_regulated_mode_major_security_events AS (
    SELECT *
    FROM {{ ref('stg_ntd__fra_regulated_mode_major_security_events') }}
),

fct_fra_regulated_mode_major_security_events AS (
    SELECT *
    FROM staging_fra_regulated_mode_major_security_events
)

SELECT * FROM fct_fra_regulated_mode_major_security_events
