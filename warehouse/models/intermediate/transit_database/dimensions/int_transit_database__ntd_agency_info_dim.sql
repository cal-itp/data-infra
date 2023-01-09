{{ config(materialized='table') }}

WITH latest_ntd_agency_info AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__ntd_agency_info'),
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
    FROM latest_ntd_agency_info
),

int_transit_database__ntd_agency_info_dim AS (
    SELECT
        {{ dbt_utils.surrogate_key(['id', '_valid_from']) }} AS key,
        id AS original_record_id,
        ntd_id,
        legacy_ntd_id,
        agency_name AS ntd_agency_name,
        reporter_acronym,
        doing_business_as,
        reporter_status,
        reporter_type,
        reporting_module,
        organization_type,
        reported_by_ntd_id,
        reported_by_name,
        subrecipient_type,
        fy_end_date,
        original_due_date,
        address_line_1,
        address_line_2,
        p_o__box,
        city,
        state,
        zip_code,
        zip_code_ext,
        region,
        url,
        fta_recipient_id,
        duns_number,
        service_area_sq_miles,
        service_area_pop,
        primary_uza,
        uza_name,
        tribal_area_name,
        population,
        density,
        sq_miles,
        voms_do,
        voms_pt,
        total_voms,
        volunteer_drivers,
        personal_vehicles,
        organization_key,
        _is_current,
        _valid_from,
        _valid_to
    FROM historical
)

SELECT * FROM int_transit_database__ntd_agency_info_dim
