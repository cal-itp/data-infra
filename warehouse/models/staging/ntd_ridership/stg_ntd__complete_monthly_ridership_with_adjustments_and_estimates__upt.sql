WITH
    source AS (
        SELECT *
          FROM {{ source('external_ntd__ridership', 'historical__complete_monthly_ridership_with_adjustments_and_estimates__upt') }}
         WHERE ntd_id IS NOT NULL
         -- Removing records without NTD_ID because contains "estimated monthly industry totals for Rural reporters" from the bottom of the scraped file
    ),

    stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__upt AS(
        SELECT *
          FROM source
        -- we pull the whole table every month in the pipeline, so this gets only the latest extract
        QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
    )

SELECT * FROM stg_ntd__complete_monthly_ridership_with_adjustments_and_estimates__upt
