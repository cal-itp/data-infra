{{ config(materialized="table") }}

WITH
    source_pivoted AS (
        {{
            dbt_utils.unpivot(
                cast_to="int",
                relation=ref("stg_ntd__operating_and_capital_funding_time_series__decommissioned_operatingfares"),
                exclude=[
                    "_2017_status",
                    "agency_status",
                    "uza_population",
                    "uza_area_sq_miles",
                    "uza",
                    "city",
                    "primary_uza_name",
                    "legacy_ntd_id",
                    "census_year",
                    "reporting_module",
                    "last_report_year",
                    "state",
                    "reporter_type",
                    "agency_name",
                    "ntd_id",
                    "dt",
                    "execution_ts"
                ],
                field_name="year",
                value_name="operating_fares",
            )
        }}
    ),

    int_ntd__operating_and_capital_funding_time_series_decommissioned_operatingfares AS (
        SELECT
            {{ dbt_utils.generate_surrogate_key(['ntd_id', 'year', 'legacy_ntd_id']) }} AS key,
            _2017_status,
            agency_status,
            uza_population,
            uza_area_sq_miles,
            uza,
            city,
            primary_uza_name,
            legacy_ntd_id,
            census_year,
            reporting_module,
            last_report_year,
            state,
            reporter_type,
            agency_name,
            SAFE_CAST((SPLIT(year, '_')[OFFSET(1)]) AS INT64) AS year,
            ntd_id,
            dt,
            execution_ts
        FROM source_pivoted
    )

SELECT * FROM int_ntd__operating_and_capital_funding_time_series_decommissioned_operatingfares
