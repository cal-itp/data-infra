WITH staging_fuel_and_energy AS (
    SELECT *
    FROM {{ ref('stg_ntd__fuel_and_energy') }}
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

fct_fuel_and_energy AS (
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
        stg.agency_voms,
        stg.bio_diesel_gal,
        stg.bio_diesel_gal_questionable,
        stg.compressed_natural_gas,
        stg.compressed_natural_gas_mpg,
        stg.compressed_natural_gas_mpg_1,
        stg.compressed_natural_gas_1,
        stg.compressed_natural_gas_gal,
        stg.compressed_natural_gas_gal_1,
        stg.diesel,
        stg.diesel_questionable,
        stg.diesel_gal,
        stg.diesel_gal_questionable,
        stg.diesel_mpg,
        stg.diesel_mpg_questionable,
        stg.electric_battery,
        stg.electric_battery_questionable,
        stg.electric_battery_kwh,
        stg.electric_battery_kwh_1,
        stg.electric_battery_mi_kwh,
        stg.electric_battery_mi_kwh_1,
        stg.electric_propulsion,
        stg.electric_propulsion_1,
        stg.electric_propulsion_kwh,
        stg.electric_propulsion_kwh_1,
        stg.electric_propulsion_mi_kwh,
        stg.electric_propulsion_mi_kwh_1,
        stg.gasoline,
        stg.gasoline_mpg,
        stg.gasoline_mpg_questionable,
        stg.gasoline_questionable,
        stg.gasoline_gal,
        stg.gasoline_gal_questionable,
        stg.hydrogen,
        stg.hydrogen_mpkg_,
        stg.hydrogen_mpkg_questionable,
        stg.hydrogen_questionable,
        stg.hydrogen_kg_,
        stg.hydrogen_kg_questionable,
        stg.liquefied_petroleum_gas,
        stg.liquefied_petroleum_gas_mpg,
        stg.liquefied_petroleum_gas_mpg_1,
        stg.liquefied_petroleum_gas_1,
        stg.liquefied_petroleum_gas_gal,
        stg.liquefied_petroleum_gas_gal_1,
        stg.mode_voms,
        stg.organization_type,
        stg.other_fuel,
        stg.other_fuel_mpg,
        stg.other_fuel_mpg_questionable,
        stg.other_fuel_questionable,
        stg.other_fuel_gal_gal_equivalent,
        stg.other_fuel_gal_gal_equivalent_1,
        stg.primary_uza_population,
        stg.reporter_type,
        stg.uace_code,
        stg.uza_name,
        stg.agency AS source_agency,
        stg.city AS source_city,
        stg.state AS source_state,
        stg.dt,
        stg.execution_ts
    FROM staging_fuel_and_energy AS stg
    LEFT JOIN dim_agency_information AS agency
        ON stg.ntd_id = agency.ntd_id
            AND stg.report_year = agency.year
)

SELECT * FROM fct_fuel_and_energy
