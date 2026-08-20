{{
    config(
        materialized='view',
        tags=['tides_reference'],
    )
}}

WITH tides_organizations_latest AS (
    SELECT * FROM {{ ref('tides_organizations') }}
    WHERE _is_current
)

SELECT * FROM tides_organizations_latest
