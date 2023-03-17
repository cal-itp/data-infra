{{ config(materialized='table') }}

WITH services AS ( -- noqa
    SELECT *
    FROM {{ ref('int_transit_database__services_dim') }}
),

geography AS ( -- noqa
    SELECT *
    FROM {{ ref('int_transit_database__county_geography_dim') }}
),

bridge_services_x_county_geography AS (
    SELECT
        services.source_record_id AS source_record_id,
        services.name AS services_name,
        geography.key AS county_geography_key,
        geography.name,
        (services._is_current AND geography._is_current) AS _is_current,
        GREATEST(services._valid_from, geography._valid_from) AS _valid_from,
        LEAST(services._valid_to, geography._valid_to) AS _valid_to
    FROM services
    INNER JOIN geography
        ON services.source_record_id = geography.service_key
        AND services._valid_from < geography._valid_to
        AND services._valid_to > geography._valid_from
)

SELECT * FROM bridge_services_x_county_geography
