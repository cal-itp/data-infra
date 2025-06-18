WITH staging_fuel_and_energy_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__fuel_and_energy_by_agency') }}
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

fct_fuel_and_energy_by_agency AS (
    SELECT
        stg.key,
        stg.ntd_id,
        stg.report_year,

        agency.agency_name,
        agency.city,
        agency.state,
        agency.caltrans_district_current,
        agency.caltrans_district_name_current,

        stg.diesel_gal_questionable,
        stg.diesel_mpg_questionable,
        stg.max_agency_voms,
        stg.max_organization_type,
        stg.max_primary_uza_population,
        stg.max_reporter_type,
        stg.max_uace_code,
        stg.max_uza_name,
        stg.sum_bio_diesel_gal,
        stg.sum_compressed_natural_gas,
        stg.sum_compressed_natural_gas_gal,
        stg.sum_diesel,
        stg.sum_diesel_gal,
        stg.sum_electric_battery,
        stg.sum_electric_battery_kwh,
        stg.sum_electric_propulsion,
        stg.sum_electric_propulsion_kwh,
        stg.sum_gasoline,
        stg.sum_gasoline_gal,
        stg.sum_hydrogen,
        stg.sum_hydrogen_kg_,
        stg.sum_liquefied_petroleum_gas,
        stg.sum_liquefied_petroleum_gas_gal,
        stg.sum_other_fuel,
        stg.sum_other_fuel_gal_gal_equivalent,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_fuel_and_energy_by_agency AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_fuel_and_energy_by_agency
