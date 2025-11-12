{{ config(materialized="table") }}

WITH
    source_pivoted AS (
        {{
            dbt_utils.unpivot(
                cast_to="int",
                relation=ref("stg_ntd__service_data_and_operating_expenses_time_series_by_mode__opexp_nvm"),
                exclude=[
                    "agency_name",
                    "agency_status",
                    "census_year",
                    "city",
                    "last_report_year",
                    "legacy_ntd_id",
                    "mode",
                    "mode_status",
                    "ntd_id",
                    "reporter_type",
                    "reporting_module",
                    "service",
                    "state",
                    "uace_code",
                    "uza_area_sq_miles",
                    "primary_uza_name",
                    "uza_population",
                    "dt",
                    "execution_ts"
                ],
                field_name="year",
                value_name="opexp_nvm",
            )
        }}
    ),

    int_ntd__service_data_and_operating_expenses_time_series_by_mode_opexp_nvm AS (
        SELECT
            {{ dbt_utils.generate_surrogate_key(['ntd_id', 'year', 'legacy_ntd_id', 'mode', 'service']) }} AS key,
            agency_name,
            agency_status,
            census_year,
            city,
            last_report_year,
            legacy_ntd_id,
            mode,
            mode_status,
            FORMAT("%05d", CAST(CAST(ntd_id AS NUMERIC) AS INT64)) AS ntd_id,
            reporter_type,
            reporting_module,
            service,
            state,
            uace_code,
            uza_area_sq_miles,
            primary_uza_name,
            uza_population,
            SAFE_CAST((SPLIT(year, '_')[OFFSET(1)]) AS INT64) AS year,
            opexp_nvm,
            dt,
            execution_ts
          FROM source_pivoted
    )

SELECT * FROM int_ntd__service_data_and_operating_expenses_time_series_by_mode_opexp_nvm
