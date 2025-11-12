{{ config(materialized="table") }}

WITH
    source_pivoted AS (
        {{
            dbt_utils.unpivot(
                cast_to="int",
                relation=ref("stg_ntd__operating_and_capital_funding_time_series__operating_total"),
                exclude=[
                    "_2024_status",
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
                value_name="operating_total",
            )
        }}
    ),

    int_ntd__operating_and_capital_funding_time_series_operating_total AS (
        SELECT
            {{ dbt_utils.generate_surrogate_key(['ntd_id', 'year', 'legacy_ntd_id']) }} AS key,
            agency_name,
            agency_status,
            census_year,
            city,
            last_report_year,
            legacy_ntd_id,
            FORMAT("%05d", CAST(CAST(ntd_id AS NUMERIC) AS INT64)) AS ntd_id,
            reporter_type,
            reporting_module,
            state,
            uace_code,
            uza_area_sq_miles,
            primary_uza_name,
            uza_population,
            SAFE_CAST((SPLIT(year, '_')[OFFSET(1)]) AS INT64) AS year,
            operating_total,
            _2024_status,
            dt,
            execution_ts
          FROM source_pivoted
    )

SELECT * FROM int_ntd__operating_and_capital_funding_time_series_operating_total
