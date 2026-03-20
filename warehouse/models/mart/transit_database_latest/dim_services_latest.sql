WITH
dim_services_latest AS (
    SELECT * FROM {{ ref('dim_services') }}
    WHERE _is_current
)

SELECT
    * EXCEPT (service_type, mode, operating_counties),
    ARRAY_TO_STRING(service_type, ", ") AS service_type,
    ARRAY_TO_STRING(mode, ", ") AS mode,
    ARRAY_TO_STRING(operating_counties, ", ") AS operating_counties
FROM dim_services_latest
