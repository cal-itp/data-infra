{{
    config(
        materialized='view',
        tags=['tides_reference'],
    )
}}

WITH tides_services_latest AS (
    SELECT * FROM {{ ref('tides_services') }}
    WHERE _is_current
)

SELECT * FROM tides_services_latest
