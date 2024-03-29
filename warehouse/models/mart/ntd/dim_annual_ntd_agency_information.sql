WITH stg_ntd__annual_database_agency_information AS (
    SELECT
        *,
        -- TODO: this does not handle deletes
        LEAD(ts) OVER (PARTITION BY year, ntd_id ORDER BY ts ASC) AS next_ts,
    FROM {{ ref('stg_ntd__annual_database_agency_information') }}
),

dim_annual_ntd_agency_information AS (
    SELECT
       {{ dbt_utils.generate_surrogate_key(['year', 'ntd_id', 'ts']) }} as key,
        year,
        ntd_id,
        number_of_state_counties,
        tam_tier,
        personal_vehicles,
        density,
        uza_name,
        tribal_area_name,
        service_area_sq_miles,
        total_voms,
        city,
        fta_recipient_id,
        region,
        state_admin_funds_expended,
        zip_code_ext,
        zip_code,
        ueid,
        address_line_2,
        number_of_counties_with_service,
        reporter_acronym,
        original_due_date,
        sq_miles,
        address_line_1,
        p_o__box,
        fy_end_date,
        reported_by_ntd_id,
        population,
        reporting_module,
        service_area_pop,
        subrecipient_type,
        state,
        volunteer_drivers,
        primary_uza,
        doing_business_as,
        reporter_type,
        legacy_ntd_id,
        voms_do,
        url,
        reported_by_name,
        voms_pt,
        organization_type,
        agency_name,
        ts AS _valid_from,
        {{ make_end_of_valid_range('COALESCE(next_ts, CAST("2099-01-01" AS TIMESTAMP))') }} AS _valid_to,
        next_ts IS NULL AS _is_current,
    FROM stg_ntd__annual_database_agency_information
)

SELECT * FROM dim_annual_ntd_agency_information
