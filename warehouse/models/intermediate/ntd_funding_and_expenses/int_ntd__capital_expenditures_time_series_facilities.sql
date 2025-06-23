{{ config(materialized="table") }}

WITH
    source_pivoted AS (
        {{
            dbt_utils.unpivot(
                cast_to="int",
                relation=ref("stg_ntd__capital_expenditures_time_series__facilities"),
                exclude=[
                    "_2023_mode_status",
                    "agency_name",
                    "agency_status",
                    "census_year",
                    "city",
                    "last_report_year",
                    "legacy_ntd_id",
                    "mode",
                    "ntd_id",
                    "reporter_type",
                    "reporting_module",
                    "state",
                    "uace_code",
                    "uza_area_sq_miles",
                    "uza_name",
                    "uza_population",
                    "dt",
                    "execution_ts"
                ],
                field_name="year",
                value_name="facilities",
            )
        }}
    ),

    int_ntd__capital_expenditures_time_series_facilities AS (
        SELECT
            agency_name,
            agency_status,
            census_year,
            city,
            last_report_year,
            legacy_ntd_id,
            mode,
            FORMAT("%05d", CAST(CAST(ntd_id AS NUMERIC) AS INT64)) AS ntd_id,
            reporter_type,
            reporting_module,
            state,
            uace_code,
            uza_area_sq_miles,
            uza_name,
            uza_population,
            SAFE_CAST((SPLIT(year, '_')[OFFSET(1)]) AS INT64) AS year,
            facilities,
            _2023_mode_status,
            dt,
            execution_ts
          FROM source_pivoted
    )

SELECT * FROM int_ntd__capital_expenditures_time_series_facilities
