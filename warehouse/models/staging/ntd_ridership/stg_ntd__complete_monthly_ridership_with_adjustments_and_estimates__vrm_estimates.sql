WITH
    stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__vrm_estimates AS(
        SELECT *
          FROM {{ source('external_ntd__ridership', 'historical__complete_monthly_ridership_with_adjustments_and_estimates__vrm_estimates') }}
        -- we pull the whole table every month in the pipeline, so this gets only the latest extract
        QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
    )

SELECT
  top_150,
  {{ trim_make_empty_string_null('CAST(ntd_id AS STRING)') }} AS ntd_id,
  agency,
  mode,
  tos,
  month,
  year,
  estimated_vrm,
  dt,
  execution_ts
FROM stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__vrm_estimates
