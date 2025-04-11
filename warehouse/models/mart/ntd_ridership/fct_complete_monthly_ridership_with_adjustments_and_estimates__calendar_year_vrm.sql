WITH staging_calendar_year_vrm AS (
    SELECT *
    FROM {{ ref('stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__calendar_year_vrm') }}
),

fct_complete_monthly_ridership_with_adjustments_and_estimates__calendar_year_vrm AS (
    SELECT *
    FROM staging_calendar_year_vrm
)

SELECT
  ntd_id,
  legacy_ntd_id,
  agency,
  mode_type_of_service_status,
  reporter_type,
  uace_cd,
  uza_name,
  mode,
  tos,
  _3_mode,
  _2002,
  _2003,
  _2004,
  _2005,
  _2006,
  _2007,
  _2008,
  _2009,
  _2010,
  _2011,
  _2012,
  _2013,
  _2014,
  _2015,
  _2016,
  _2017,
  _2018,
  _2019,
  _2020,
  _2021,
  _2022,
  _2023,
  _2024,
  dt,
  execution_ts
FROM fct_complete_monthly_ridership_with_adjustments_and_estimates__calendar_year_vrm
