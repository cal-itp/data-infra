{{ config(materialized="table") }}

WITH
    source_pivoted AS (
        {{
            dbt_utils.unpivot(
                cast_to="int",
                relation=ref("stg_ntd__operating_and_capital_funding_time_series__capital_state"),
                exclude=[
                    "_2023_status",
                    "agency_name",
                    "agency_status",
                    "census_year",
                    "city",
                    "last_report_year",
                    "legacy_ntd_id",
                    "ntd_id",
                    "reporter_type",
                    "reporting_module",
                    "state",
                    "uace_code",
                    "uza_area_sq_miles",
                    "primary_uza_name",
                    "uza_population",
                    "dt",
                    "execution_ts"
                ],
                field_name="year",
                value_name="capital_state",
            )
        }}
    ),

    int_ntd__operating_and_capital_funding_time_series_capital_state AS (
        SELECT
            agency_name,
            agency_status,
            census_year,
            city,
            last_report_year,
            legacy_ntd_id,
            format("%05d", cast(cast(ntd_id AS NUMERIC) AS INT64)) AS ntd_id,
            reporter_type,
            reporting_module,
            state,
            uace_code,
            uza_area_sq_miles,
            primary_uza_name,
            uza_population,
            split(year, '_')[offset(1)] AS year,
            capital_state,
            _2023_status,
            dt,
            execution_ts
          FROM source_pivoted
    )

SELECT * FROM int_ntd__operating_and_capital_funding_time_series_capital_state
