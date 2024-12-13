WITH external_major_safety_events AS (
    SELECT *
    FROM {{ source('external_ntd__safety_and_security', 'historical__major_safety_events') }}
),

get_latest_extract AS(

    SELECT *
    FROM external_major_safety_events
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
),

stg_ntd_safety_and_security__major_safety_events AS (
    SELECT *
    FROM get_latest_extract
)

SELECT * FROM stg_ntd_safety_and_security__major_safety_events
