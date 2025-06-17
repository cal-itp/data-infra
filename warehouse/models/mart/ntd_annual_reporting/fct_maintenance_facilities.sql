WITH staging_maintenance_facilities AS (
    SELECT *
    FROM {{ ref('stg_ntd__maintenance_facilities') }}
    -- remove bad rows for 'Advance Transit, Inc. NH' and 'Southern Teton Area Rapid Transit'
    WHERE key NOT IN ('1bebb98cd526881d0beab080dafd1e6a','f8b280fb1301a54725feefa098f519ec','1d5f79c7f06b68f023dd6513f8d797d4',
        '33c3d376e7d93b04c210041d62e015f2','e1503c0491fb6666f060aa64276fb707','9078bab61ab02779f9a4a5b043e377d9',
        '04804150c414bd12329423ebf09442fd','61eeee88a89ab9a2e63c24ac99d297b8','faf75088d148925ea862051b49b54429',
        '1e9138bb433fed360f111c90866fc94a')
),

dim_agency_information AS (
    SELECT
        ntd_id,
        year,
        agency_name,
        city,
        state,
        caltrans_district_current,
        caltrans_district_name_current
    FROM {{ ref('dim_agency_information') }}
),

fct_maintenance_facilities AS (
    SELECT
        stg.key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.mode,
        stg.mode_name,
        stg.type_of_service,
        stg._200_to_300_vehicles,
        stg._200_to_300_vehicles_1,
        stg.agency_voms,
        stg.heavy_maintenance_facilities,
        stg.heavy_maintenance_facilities_1,
        stg.leased_by_pt_provider,
        stg.leased_by_pt_provider_1,
        stg.leased_by_public_agency,
        stg.leased_by_public_agency_1,
        stg.leased_from_a_private_entity,
        stg.leased_from_a_private_entity_1,
        stg.leased_from_a_public_entity,
        stg.leased_from_a_public_entity_1,
        stg.mode_voms,
        stg.organization_type,
        stg.over_300_vehicles,
        stg.over_300_vehicles_questionable,
        stg.owned,
        stg.owned_questionable,
        stg.owned_by_pt_provider,
        stg.owned_by_pt_provider_1,
        stg.owned_by_public_agency,
        stg.owned_by_public_agency_1,
        stg.primary_uza_population,
        stg.reporter_type,
        stg.total_facilities,
        stg.total_maintenance_facilities,
        stg.uace_code,
        stg.under_200_vehicles,
        stg.under_200_vehicles_1,
        stg.uza_name,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_maintenance_facilities AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_maintenance_facilities
