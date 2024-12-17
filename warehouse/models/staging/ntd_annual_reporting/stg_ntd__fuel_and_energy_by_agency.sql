WITH external_fuel_and_energy_by_agency AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', 'multi_year__fuel_and_energy_by_agency') }}
),

get_latest_extract AS(
    SELECT *
    FROM external_fuel_and_energy_by_agency
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__fuel_and_energy_by_agency AS (
    SELECT *
    FROM get_latest_extract
)

SELECT
    SAFE_CAST(diesel_gal_questionable AS NUMERIC) AS diesel_gal_questionable,
    SAFE_CAST(diesel_mpg_questionable AS NUMERIC) AS diesel_mpg_questionable,
    {{ trim_make_empty_string_null('max_agency') }} AS max_agency,
    SAFE_CAST(max_agency_voms AS NUMERIC) AS max_agency_voms,
    {{ trim_make_empty_string_null('max_city') }} AS max_city,
    {{ trim_make_empty_string_null('max_organization_type') }} AS max_organization_type,
    SAFE_CAST(max_primary_uza_population AS NUMERIC) AS max_primary_uza_population,
    {{ trim_make_empty_string_null('max_reporter_type') }} AS max_reporter_type,
    {{ trim_make_empty_string_null('max_state') }} AS max_state,
    {{ trim_make_empty_string_null('max_uace_code') }} AS max_uace_code,
    {{ trim_make_empty_string_null('max_uza_name') }} AS max_uza_name,
    {{ trim_make_empty_string_null('ntd_id') }} AS ntd_id,
    {{ trim_make_empty_string_null('report_year') }} AS report_year,
    SAFE_CAST(sum_bio_diesel_gal AS NUMERIC) AS sum_bio_diesel_gal,
    SAFE_CAST(sum_compressed_natural_gas AS NUMERIC) AS sum_compressed_natural_gas,
    SAFE_CAST(sum_compressed_natural_gas_gal AS NUMERIC) AS sum_compressed_natural_gas_gal,
    SAFE_CAST(sum_diesel AS NUMERIC) AS sum_diesel,
    SAFE_CAST(sum_diesel_gal AS NUMERIC) AS sum_diesel_gal,
    SAFE_CAST(sum_electric_battery AS NUMERIC) AS sum_electric_battery,
    SAFE_CAST(sum_electric_battery_kwh AS NUMERIC) AS sum_electric_battery_kwh,
    SAFE_CAST(sum_electric_propulsion AS NUMERIC) AS sum_electric_propulsion,
    SAFE_CAST(sum_electric_propulsion_kwh AS NUMERIC) AS sum_electric_propulsion_kwh,
    SAFE_CAST(sum_gasoline AS NUMERIC) AS sum_gasoline,
    SAFE_CAST(sum_gasoline_gal AS NUMERIC) AS sum_gasoline_gal,
    SAFE_CAST(sum_hydrogen AS NUMERIC) AS sum_hydrogen,
    SAFE_CAST(sum_hydrogen_kg_ AS NUMERIC) AS sum_hydrogen_kg_,
    SAFE_CAST(sum_liquefied_petroleum_gas AS NUMERIC) AS sum_liquefied_petroleum_gas,
    SAFE_CAST(sum_liquefied_petroleum_gas_gal AS NUMERIC) AS sum_liquefied_petroleum_gas_gal,
    SAFE_CAST(sum_other_fuel AS NUMERIC) AS sum_other_fuel,
    SAFE_CAST(sum_other_fuel_gal_gal_equivalent AS NUMERIC) AS sum_other_fuel_gal_gal_equivalent,
    dt,
    execution_ts
FROM stg_ntd__fuel_and_energy_by_agency
