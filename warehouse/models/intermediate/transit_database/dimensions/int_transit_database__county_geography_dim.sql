{{ config(materialized='table') }}

WITH latest_county_geography AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__county_geography'),
        order_by = 'dt DESC'
        ) }}
),

-- TODO: make this table actually historical
historical AS (
    SELECT
        *,
        TRUE AS _is_current,
        CAST(universal_first_val AS TIMESTAMP) AS _valid_from,
        {{ make_end_of_valid_range('CAST("2099-01-01" AS TIMESTAMP)') }} AS _valid_to
    FROM latest_county_geography
),

int_transit_database__county_geography AS (
    SELECT
        {{ dbt_utils.surrogate_key(['id', '_valid_from']) }} AS key,
        id AS source_record_id,
        name,
        fips,
        msa,
        caltrans_district,
        caltrans_district_name,
        -- rtpa is not a one-to-one relationship
        rtpa,
        mpo,
        place_geography,
        organizations AS organization_key,
        services AS service_key,
        _is_current,
        _valid_from,
        _valid_to
    FROM historical
)

SELECT * FROM int_transit_database__county_geography
