{{ config(materialized="table") }}

WITH
    source_pivoted AS (
        {{
            dbt_utils.unpivot(
                cast_to="int",
                relation=ref("stg_ntd__asset_inventory_time_series__avg_fleet_age"),
                exclude=[
                    "state",
                    "uza_area_sq_miles",
                    "ntd_id",
                    "legacy_ntd_id",
                    "uace_code",
                    "last_report_year",
                    "mode_status",
                    "service",
                    "_2024_mode_status",
                    "agency_status",
                    "uza_population",
                    "mode",
                    "uza_name",
                    "city",
                    "census_year",
                    "reporting_module",
                    "reporter_type",
                    "agency_name",
                    "dt",
                    "execution_ts"
                ],
                field_name="year",
                value_name="total",
            )
        }}
    ),

    int_ntd__asset_inventory_time_series_avg_fleet_age AS (
        SELECT
            {{ dbt_utils.generate_surrogate_key(['ntd_id', 'year', 'legacy_ntd_id', 'mode', 'service']) }} AS key,
            -- Extract the year number from the string (e.g., '_2021' -> 2021) and ensure it's an INT64
            -- This is needed for proper comparison with dim_agency_information.year which is an INT64
            SAFE_CAST(REGEXP_EXTRACT(year, r'_(\d+)') AS INT64) AS year,
            total,
            state,
            uza_area_sq_miles,
            ntd_id,
            legacy_ntd_id,
            uace_code,
            last_report_year,
            mode_status,
            service,
            _2024_mode_status,
            agency_status,
            uza_population,
            mode,
            uza_name,
            city,
            census_year,
            reporting_module,
            reporter_type,
            agency_name,
            dt,
            execution_ts
        FROM source_pivoted
    )

SELECT * FROM int_ntd__asset_inventory_time_series_avg_fleet_age
