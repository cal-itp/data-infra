WITH external_contractual_relationships AS (
    SELECT *
    FROM {{ source('external_ntd__annual_reporting', '2023__annual_database_contractual_relationship') }}
),

get_latest_extract AS(

    SELECT *
    FROM external_contractual_relationships
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd__2023_contractual_relationships AS (
    SELECT *
    FROM get_latest_extract
)

SELECT * FROM stg_ntd__2023_contractual_relationships
