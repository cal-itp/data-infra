WITH
dim_services_latest AS (
    SELECT * FROM {{ ref('dim_services') }}
    WHERE _is_current
)

SELECT * FROM dim_services_latest
