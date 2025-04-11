WITH staging_fuel_and_energy_by_agency AS (
    SELECT *
    FROM {{ ref('stg_ntd__fuel_and_energy_by_agency') }}
),

current_dim_organizations AS (
    SELECT
        ntd_id,
        caltrans_district
    FROM {{ ref('dim_organizations') }}
    WHERE _is_current
),

enrich_with_caltrans_district AS (
    SELECT
        staging_fuel_and_energy_by_agency.*,
        current_dim_organizations.caltrans_district
    FROM staging_fuel_and_energy_by_agency
    LEFT JOIN current_dim_organizations USING (ntd_id)
),

fct_fuel_and_energy_by_agency AS (
    SELECT *
    FROM enrich_with_caltrans_district
)

SELECT
    diesel_gal_questionable,
    diesel_mpg_questionable,
    max_agency,
    max_agency_voms,
    max_city,
    max_organization_type,
    max_primary_uza_population,
    max_reporter_type,
    max_state,
    max_uace_code,
    max_uza_name,
    ntd_id,
    report_year,
    sum_bio_diesel_gal,
    sum_compressed_natural_gas,
    sum_compressed_natural_gas_gal,
    sum_diesel,
    sum_diesel_gal,
    sum_electric_battery,
    sum_electric_battery_kwh,
    sum_electric_propulsion,
    sum_electric_propulsion_kwh,
    sum_gasoline,
    sum_gasoline_gal,
    sum_hydrogen,
    sum_hydrogen_kg_,
    sum_liquefied_petroleum_gas,
    sum_liquefied_petroleum_gas_gal,
    sum_other_fuel,
    sum_other_fuel_gal_gal_equivalent,
    caltrans_district,
    dt,
    execution_ts
FROM fct_fuel_and_energy_by_agency
