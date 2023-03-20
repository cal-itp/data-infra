{{ config(materialized='table') }}

WITH orgs AS ( -- noqa
    SELECT *
    FROM {{ ref('int_transit_database__organizations_dim') }}
),

geography AS ( -- noqa
    SELECT *
    FROM {{ ref('int_transit_database__county_geography_dim') }}
),

bridge_organizations_x_county_geography AS (
    SELECT
        orgs.key AS organization_key,
        orgs.name AS organization_name,
        geography.key AS county_geography_key,
        geography.name,
        (orgs._is_current AND geography._is_current) AS _is_current,
        GREATEST(orgs._valid_from, geography._valid_from) AS _valid_from,
        LEAST(orgs._valid_to, geography._valid_to) AS _valid_to
    FROM orgs
    INNER JOIN geography
        ON orgs.source_record_id = geography.organization_key
        AND orgs._valid_from < geography._valid_to
        AND orgs._valid_to > geography._valid_from
)

SELECT * FROM bridge_organizations_x_county_geography
