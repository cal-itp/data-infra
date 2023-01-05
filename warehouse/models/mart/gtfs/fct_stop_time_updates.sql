WITH

fct_trip_updates_messages AS (
    SELECT * FROM {{ ref('fct_trip_updates_messages') }}
),

fct_stop_time_updates AS (
    SELECT
        {{ dbt_utils.surrogate_key(['base64_url',
                                    '_extract_ts',
                                    'trip_id',
                                    'stop_time_update.stopSequence',
        ]) }} as key,
        fct_trip_updates_messages.* EXCEPT (key),
        stop_time_update.stopSequence AS stop_sequence,
        stop_time_update.stopId AS stop_id,
        stop_time_update.arrival.delay AS arrival_delay,
        stop_time_update.arrival.time AS arrival_time,
        stop_time_update.arrival.uncertainty AS arrival_uncertainty,
        stop_time_update.departure.delay AS departure_delay,
        stop_time_update.departure.time AS departure_time,
        stop_time_update.departure.uncertainty AS departure_uncertainty,
        stop_time_update.scheduleRelationship AS schedule_relationship,
    FROM fct_trip_updates_messages
    LEFT JOIN UNNEST(stop_time_updates) AS stop_time_update
)

SELECT * FROM fct_stop_time_updates
