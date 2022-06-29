{{ config(materialized='table') }}

WITH
latest AS (
    {{ get_latest_external_data(
        external_table = source('airtable', 'california_transit__place_geography'),
        order_by = 'dt DESC, time DESC'
        ) }}
),

stg_transit_database__place_geography AS (
    SELECT
        place_geography_id AS key,
        {{ trim_make_empty_string_null(column_name = "name") }},
        place_fips,
        placename,
        type,
        place_base,
        place_formal,
        county,
        unnested_county_base AS county_geography_key,
        fips__from_county_base_,
        msa__from_county_base_,
        caltrans_district__from_county_base_,
        caltrans_district_name__from_county_base_,
        rtpa__from_county_base_,
        mpo__from_county_base_,
        organizations_2,
        time,
        dt AS calitp_extracted_at
    FROM latest
    LEFT JOIN UNNEST(latest.county_base) AS unnested_county_base
)

SELECT * FROM stg_transit_database__place_geography
