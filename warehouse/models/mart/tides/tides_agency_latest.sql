{{
    config(
        materialized='view',
        tags=['tides_reference'],
    )
}}

WITH tides_agency_latest AS (
    SELECT * FROM {{ ref('tides_agency') }}
    WHERE _is_current
)

SELECT * FROM tides_agency_latest
