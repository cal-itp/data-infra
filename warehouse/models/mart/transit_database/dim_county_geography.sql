{{ config(materialized='table') }}

WITH int_transit_database__county_geography_dim AS (
    SELECT *
    FROM {{ ref('int_transit_database__county_geography_dim') }}
),

dim_county_geography AS (
    SELECT

        key,
        source_record_id,
        name,
        fips,
        msa,
        caltrans_district,
        caltrans_district_name,
        place_geography,
        organization_key,
        service_key,
        _is_current,
        _valid_from,
        _valid_to

    FROM int_transit_database__county_geography_dim
)

SELECT * FROM dim_county_geography
