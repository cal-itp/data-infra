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
    SELECT
        {{ dbt_utils.generate_surrogate_key(['ntd_id', 'report_year', 'modecd', 'typeofservicecd']) }} AS key,
        {{ trim_make_empty_string_null('agency') }} AS agency,
        SAFE_CAST(agency_voms AS NUMERIC) AS agency_voms,
        SAFE_CAST(bio_diesel_gal AS NUMERIC) AS bio_diesel_gal,
        {{ trim_make_empty_string_null('bio_diesel_gal_questionable') }} AS bio_diesel_gal_questionable,
        {{ trim_make_empty_string_null('city') }} AS city,
        SAFE_CAST(compressed_natural_gas AS NUMERIC) AS compressed_natural_gas,
        SAFE_CAST(compressed_natural_gas_mpg AS NUMERIC) AS compressed_natural_gas_mpg,
        {{ trim_make_empty_string_null('compressed_natural_gas_mpg_1') }} AS compressed_natural_gas_mpg_1,
        {{ trim_make_empty_string_null('compressed_natural_gas_1') }} AS compressed_natural_gas_1,
        SAFE_CAST(compressed_natural_gas_gal AS NUMERIC) AS compressed_natural_gas_gal,
        {{ trim_make_empty_string_null('compressed_natural_gas_gal_1') }} AS compressed_natural_gas_gal_1,
        SAFE_CAST(diesel AS NUMERIC) AS diesel,
        {{ trim_make_empty_string_null('diesel_questionable') }} AS diesel_questionable,
        SAFE_CAST(diesel_gal AS NUMERIC) AS diesel_gal,
        {{ trim_make_empty_string_null('diesel_gal_questionable') }} AS diesel_gal_questionable,
        SAFE_CAST(diesel_mpg AS NUMERIC) AS diesel_mpg,
        {{ trim_make_empty_string_null('diesel_mpg_questionable') }} AS diesel_mpg_questionable,
        SAFE_CAST(electric_battery AS NUMERIC) AS electric_battery,
        {{ trim_make_empty_string_null('electric_battery_questionable') }} AS electric_battery_questionable,
        SAFE_CAST(electric_battery_kwh AS NUMERIC) AS electric_battery_kwh,
        {{ trim_make_empty_string_null('electric_battery_kwh_1') }} AS electric_battery_kwh_1,
        SAFE_CAST(electric_battery_mi_kwh AS NUMERIC) AS electric_battery_mi_kwh,
        {{ trim_make_empty_string_null('electric_battery_mi_kwh_1') }} AS electric_battery_mi_kwh_1,
        SAFE_CAST(electric_propulsion AS NUMERIC) AS electric_propulsion,
        {{ trim_make_empty_string_null('electric_propulsion_1') }} AS electric_propulsion_1,
        SAFE_CAST(electric_propulsion_kwh AS NUMERIC) AS electric_propulsion_kwh,
        {{ trim_make_empty_string_null('electric_propulsion_kwh_1') }} AS electric_propulsion_kwh_1,
        SAFE_CAST(electric_propulsion_mi_kwh AS NUMERIC) AS electric_propulsion_mi_kwh,
        {{ trim_make_empty_string_null('electric_propulsion_mi_kwh_1') }} AS electric_propulsion_mi_kwh_1,
        SAFE_CAST(gasoline AS NUMERIC) AS gasoline,
        SAFE_CAST(gasoline_mpg AS NUMERIC) AS gasoline_mpg,
        {{ trim_make_empty_string_null('gasoline_mpg_questionable') }} AS gasoline_mpg_questionable,
        {{ trim_make_empty_string_null('gasoline_questionable') }} AS gasoline_questionable,
        SAFE_CAST(gasoline_gal AS NUMERIC) AS gasoline_gal,
        {{ trim_make_empty_string_null('gasoline_gal_questionable') }} AS gasoline_gal_questionable,
        SAFE_CAST(hydrogen AS NUMERIC) AS hydrogen,
        SAFE_CAST(hydrogen_mpkg_ AS NUMERIC) AS hydrogen_mpkg_,
        {{ trim_make_empty_string_null('hydrogen_mpkg_questionable') }} AS hydrogen_mpkg_questionable,
        {{ trim_make_empty_string_null('hydrogen_questionable') }} AS hydrogen_questionable,
        SAFE_CAST(hydrogen_kg_ AS NUMERIC) AS hydrogen_kg_,
        {{ trim_make_empty_string_null('hydrogen_kg_questionable') }} AS hydrogen_kg_questionable,
        SAFE_CAST(liquefied_petroleum_gas AS NUMERIC) AS liquefied_petroleum_gas,
        SAFE_CAST(liquefied_petroleum_gas_mpg AS NUMERIC) AS liquefied_petroleum_gas_mpg,
        {{ trim_make_empty_string_null('liquefied_petroleum_gas_mpg_1') }} AS liquefied_petroleum_gas_mpg_1,
        {{ trim_make_empty_string_null('liquefied_petroleum_gas_1') }} AS liquefied_petroleum_gas_1,
        SAFE_CAST(liquefied_petroleum_gas_gal AS NUMERIC) AS liquefied_petroleum_gas_gal,
        {{ trim_make_empty_string_null('liquefied_petroleum_gas_gal_1') }} AS liquefied_petroleum_gas_gal_1,
        {{ trim_make_empty_string_null('mode_name') }} AS mode_name,
        SAFE_CAST(mode_voms AS NUMERIC) AS mode_voms,
        {{ trim_make_empty_string_null('modecd') }} AS mode,
        {{ trim_make_empty_string_null('CAST(ntd_id AS STRING)') }} AS ntd_id,
        {{ trim_make_empty_string_null('organization_type') }} AS organization_type,
        SAFE_CAST(other_fuel AS NUMERIC) AS other_fuel,
        SAFE_CAST(other_fuel_mpg AS NUMERIC) AS other_fuel_mpg,
        {{ trim_make_empty_string_null('other_fuel_mpg_questionable') }} AS other_fuel_mpg_questionable,
        {{ trim_make_empty_string_null('other_fuel_questionable') }} AS other_fuel_questionable,
        SAFE_CAST(other_fuel_gal_gal_equivalent AS NUMERIC) AS other_fuel_gal_gal_equivalent,
        {{ trim_make_empty_string_null('other_fuel_gal_gal_equivalent_1') }} AS other_fuel_gal_gal_equivalent_1,
        SAFE_CAST(primary_uza_population AS NUMERIC) AS primary_uza_population,
        SAFE_CAST(report_year AS INT64) AS report_year,
        {{ trim_make_empty_string_null('reporter_type') }} AS reporter_type,
        {{ trim_make_empty_string_null('state') }} AS state,
        {{ trim_make_empty_string_null('typeofservicecd') }} AS type_of_service,
        {{ trim_make_empty_string_null('uace_code') }} AS uace_code,
        {{ trim_make_empty_string_null('uza_name') }} AS uza_name,
        dt,
        execution_ts
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__fuel_and_energy
