WITH external_fuel_and_energy AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__fuel_and_energy') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_fuel_and_energy
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__fuel_and_energy AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    agency,
    agency_voms,
    bio_diesel_gal,
    bio_diesel_gal_questionable,
    city,
    compressed_natural_gas,
    compressed_natural_gas_mpg,
    compressed_natural_gas_mpg_1,
    compressed_natural_gas_1,
    compressed_natural_gas_gal,
    compressed_natural_gas_gal_1,
    diesel,
    diesel_questionable,
    diesel_gal,
    diesel_gal_questionable,
    diesel_mpg,
    diesel_mpg_questionable,
    electric_battery,
    electric_battery_questionable,
    electric_battery_kwh,
    electric_battery_kwh_1,
    electric_battery_mi_kwh,
    electric_battery_mi_kwh_1,
    electric_propulsion,
    electric_propulsion_1,
    electric_propulsion_kwh,
    electric_propulsion_kwh_1,
    electric_propulsion_mi_kwh,
    electric_propulsion_mi_kwh_1,
    gasoline,
    gasoline_mpg,
    gasoline_mpg_questionable,
    gasoline_questionable,
    gasoline_gal,
    gasoline_gal_questionable,
    hydrogen,
    hydrogen_mpkg_,
    hydrogen_mpkg_questionable,
    hydrogen_questionable,
    hydrogen_kg_,
    hydrogen_kg_questionable,
    liquefied_petroleum_gas,
    liquefied_petroleum_gas_mpg,
    liquefied_petroleum_gas_mpg_1,
    liquefied_petroleum_gas_1,
    liquefied_petroleum_gas_gal,
    liquefied_petroleum_gas_gal_1,
    mode_name,
    mode_voms,
    modecd,
    ntd_id,
    organization_type,
    other_fuel,
    other_fuel_mpg,
    other_fuel_mpg_questionable,
    other_fuel_questionable,
    other_fuel_gal_gal_equivalent,
    other_fuel_gal_gal_equivalent_1,
    primary_uza_population,
    report_year,
    reporter_type,
    state,
    typeofservicecd,
    uace_code,
    uza_name,
    dt,
    execution_ts
FROM stg_ntd__fuel_and_energy
