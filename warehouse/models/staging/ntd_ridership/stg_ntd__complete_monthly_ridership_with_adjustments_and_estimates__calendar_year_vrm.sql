WITH
  source AS (
      SELECT *
        FROM {{ source('external_ntd__ridership', 'historical__complete_monthly_ridership_with_adjustments_and_estimates__calendar_year_vrm') }}
        WHERE ntd_id IS NOT NULL
        -- Removing records without NTD_ID because contains "estimated monthly industry totals for Rural reporters" from the bottom of the scraped file
  ),

  stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__calendar_year_vrm AS(
      SELECT *
        FROM source
      -- we pull the whole table every month in the pipeline, so this gets only the latest extract
      QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
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
FROM stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__calendar_year_vrm
