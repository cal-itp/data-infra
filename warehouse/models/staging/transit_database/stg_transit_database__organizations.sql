WITH

once_daily_organizations AS (
    {{ get_latest_dense_rank(
        external_table = source('airtable', 'california_transit__organizations'),
        order_by = 'ts DESC', partition_by = 'dt'
        ) }}
),

stg_transit_database__organizations AS (
    SELECT
        id,
        {{ trim_make_empty_string_null(column_name = "name") }} AS name,
        organization_type,
        roles,
        CASE
            -- only correct records while they were actively incorrect, don't hard code in general
            -- just in case there are legitimate changes upstream
            -- correct Cloverdale having Long Beach ITP ID
            WHEN id = 'recRM3c9Zfaft4V2B' AND itp_id = 170 THEN 70
            -- correct City of Madera having Madera County ITP ID
            WHEN id = 'rec2DteW2sfmBJRsH' AND itp_id = 188 THEN 187
            ELSE CAST(itp_id AS INTEGER)
        END AS itp_id,
        {{ trim_make_empty_string_null('unnested_ntd_records') }} AS ntd_agency_info_key,
        hubspot_company_record_id,
        alias_ as alias,
        details,
        mobility_services_managed,
        parent_organization,
        website,
        reporting_category,
        funding_programs,
        gtfs_datasets_produced,
        gtfs_static_status,
        gtfs_realtime_status,
        assessment_status = "Yes" AS assessment_status,
        manual_check__contact_on_website,
        dt,
        hq_county_geography,
        is_public_entity = "Yes" AS is_public_entity,
        raw_ntd_id,
        ntd_id_2022,
        unnested_rtpa as rtpa,
        unnested_mpo as mpo,
        public_currently_operating = "Yes" AS public_currently_operating,
        public_currently_operating_fixed_route = "Yes" AS public_currently_operating_fixed_route,
    FROM once_daily_organizations
    LEFT JOIN UNNEST(once_daily_organizations.ntd_id) as unnested_ntd_records
    LEFT JOIN UNNEST(once_daily_organizations.rtpa) AS unnested_rtpa
    LEFT JOIN UNNEST(once_daily_organizations.mpo) AS unnested_mpo

)

SELECT * FROM stg_transit_database__organizations
