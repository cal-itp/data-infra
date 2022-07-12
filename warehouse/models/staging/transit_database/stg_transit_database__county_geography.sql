

WITH
latest AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'california_transit__county_geography'),
        order_by = 'time DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__county_geography AS (
    SELECT
        id AS key,
        {{ trim_make_empty_string_null(column_name = "name") }},
        fips,
        msa,
        caltrans_district,
        caltrans_district_name,
        -- rtpa is not a one-to-one relationship
        rtpa,
        mpo,
        place_geography,
        time,
        dt AS calitp_extracted_at
    FROM latest
)

SELECT * FROM stg_transit_database__county_geography
