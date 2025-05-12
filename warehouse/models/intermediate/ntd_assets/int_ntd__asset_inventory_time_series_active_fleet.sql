{{ config(materialized="table") }}

WITH
    source_pivoted AS (
        {{
            dbt_utils.unpivot(
                cast_to="int",
                relation=ref("stg_ntd__asset_inventory_time_series__active_fleet"),
                exclude=[
                    "state",
                    "uza_area_sq_miles",
                    "ntd_id",
                    "legacy_ntd_id",
                    "uace_code",
                    "last_report_year",
                    "mode_status",
                    "service",
                    "_2023_mode_status",
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

    int_ntd__asset_inventory_time_series_active_fleet AS (
        SELECT
            split(year, '_')[offset(1)] AS year,
            total,
            state,
            uza_area_sq_miles,
            ntd_id,
            legacy_ntd_id,
            uace_code,
            last_report_year,
            mode_status,
            service,
            _2023_mode_status,
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

SELECT * FROM int_ntd__asset_inventory_time_series_active_fleet
