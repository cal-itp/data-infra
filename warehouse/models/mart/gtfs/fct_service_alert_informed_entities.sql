WITH messages AS (
    SELECT *
    FROM {{ ref('fct_service_alerts_messages') }}
),

fct_service_alerts_informed_entities AS (
    SELECT
        messages.* EXCEPT(
            key,
            informed_entity
        ),
        key AS service_alert_message_key,

        {{ dbt_utils.surrogate_key(['key', 'unnested_informed_entity.agencyId',
            'unnested_informed_entity.routeId', 'unnested_informed_entity.trip.tripId',
            'unnested_informed_entity.stopId']) }} AS key,

        unnested_informed_entity.agencyId AS agency_id,
        unnested_informed_entity.routeId AS route_id,
        unnested_informed_entity.routeType AS route_type,
        unnested_informed_entity.directionId AS direction_id,
        unnested_informed_entity.trip.tripId AS trip_id,
        unnested_informed_entity.trip.routeId AS trip_route_id,
        unnested_informed_entity.trip.directionId AS trip_direction_id,
        unnested_informed_entity.trip.startTime AS trip_start_time,
        unnested_informed_entity.trip.startDate AS trip_start_date,
        unnested_informed_entity.trip.scheduleRelationship AS trip_schedule_relationship,
        unnested_informed_entity.stopId AS stop_id
    FROM messages
    -- https://stackoverflow.com/questions/44918108/google-bigquery-i-lost-null-row-when-using-unnest-function
    -- these arrays may have nulls
    LEFT JOIN UNNEST(messages.informed_entity) AS unnested_informed_entity
)

SELECT * FROM fct_service_alerts_informed_entities
