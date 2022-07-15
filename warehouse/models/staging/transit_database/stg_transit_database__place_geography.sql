

WITH
once_daily_place_geography AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'california_transit__place_geography'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__place_geography AS (
    SELECT
        id AS key,
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
        ts,
        dt AS calitp_extracted_at
    FROM once_daily_place_geography
    LEFT JOIN UNNEST(once_daily_place_geography.county_base) AS unnested_county_base
)

SELECT * FROM stg_transit_database__place_geography
