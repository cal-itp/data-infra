WITH staging_fuel_and_energy_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__fuel_and_energy_by_agency') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district AS caltrans_district_current,
        caltrans_district_name AS caltrans_district_name_current
    FROM {{ ref('dim_organizations_latest_with_caltrans_district') }}
),

fct_fuel_and_energy_by_agency AS (
    SELECT
        stg.max_agency AS agency_name,
        stg.ntd_id,
        stg.report_year,
        stg.max_city AS city,
        stg.max_state AS state,
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

        orgs.caltrans_district_current,
        orgs.caltrans_district_name_current,

        stg.dt,
        stg.execution_ts
    FROM staging_fuel_and_energy_by_agency AS stg
    LEFT JOIN current_dim_organizations AS orgs USING (ntd_id)
)

SELECT * FROM fct_fuel_and_energy_by_agency
