WITH external_state_geoportal__state_highway_network AS (
    SELECT *
    FROM
    --`cal-itp-data-infra-staging.external_state_geoportal.state_highway_network`
    {{ source('external_state_geoportal', 'state_highway_network') }}
),

stg_state_geoportal__state_highway_network_stops AS(

    SELECT *
    FROM external_state_geoportal__state_highway_network
    -- we pull the whole table every month in the pipeline, so this gets only the latest extract
    QUALIFY DENSE_RANK() OVER (ORDER BY execution_ts DESC) = 1
)

SELECT * FROM stg_state_geoportal__state_highway_network_stops
