{{ config(materialized='table') }}

WITH fct_vehicle_locations AS (
    SELECT
        key,
        gtfs_dataset_key,
        base64_url,
        gtfs_dataset_name,
        schedule_gtfs_dataset_key,
        service_date,
        trip_instance_key,
        location_timestamp,
        location,
        next_location_key,
    FROM {{ ref('fct_vehicle_locations') }}
    WHERE gtfs_dataset_name="LA DOT VehiclePositions" AND service_date = "2025-01-07" --AND (trip_instance_key="0000a63ce280462e6eed4f3ae92df16d" OR trip_instance_key="ec14aa25e209f90ed025450c18519814")
    ORDER by service_date, trip_instance_key, location_timestamp
    ),


get_next AS (
    SELECT
        key AS next_location_key,
        location AS next_location,
    FROM fct_vehicle_locations
),

vp_groupings AS (
    SELECT
        fct_vehicle_locations.key,
        fct_vehicle_locations.next_location_key,
        CASE
            WHEN ST_EQUALS(fct_vehicle_locations.location, get_next.next_location)
            THEN 0
            ELSE 1
        END AS new_group,
    FROM fct_vehicle_locations
    INNER JOIN get_next
        ON fct_vehicle_locations.next_location_key = get_next.next_location_key
),

merged AS (
    SELECT
        fct_vehicle_locations.key AS key,
        -- vp_group should increase from 1, 2, ... , n, depending on number of groups are present within a trip
        SUM(
            COALESCE(vp_groupings.new_group, 1)
        )
            OVER (
                PARTITION BY service_date, trip_instance_key
                ORDER BY location_timestamp
                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
            )  AS vp_group,
    FROM fct_vehicle_locations
    INNER JOIN vp_groupings
        ON fct_vehicle_locations.key = vp_groupings.key AND fct_vehicle_locations.next_location_key = vp_groupings.next_location_key
),

fct_vp_dwell AS (
    SELECT
        MIN(fct_vehicle_locations.key) as key,
        fct_vehicle_locations.gtfs_dataset_key,
        fct_vehicle_locations.base64_url,
        fct_vehicle_locations.gtfs_dataset_name,
        fct_vehicle_locations.schedule_gtfs_dataset_key,
        fct_vehicle_locations.trip_instance_key as trip_instance_key,
        fct_vehicle_locations.service_date as service_date,
        --merged.vp_group AS vp_group,
        MIN(fct_vehicle_locations.location_timestamp) AS location_timestamp,
        MAX(fct_vehicle_locations.location_timestamp) AS moving_timestamp,
        COUNT(*) AS n_vp,
        ST_GEOGFROMTEXT(MIN(ST_ASTEXT(fct_vehicle_locations.location))) AS location,
        -- location as geography column can't be included in group by,
        -- so let's just grab first value of string and coerce back to geography
    FROM fct_vehicle_locations
    LEFT JOIN merged
        ON fct_vehicle_locations.key = merged.key
    GROUP BY service_date, gtfs_dataset_key, base64_url, gtfs_dataset_name, schedule_gtfs_dataset_key, trip_instance_key, vp_group
)

-- can we roll in n_vp + location into merged
-- without the last merge? how to group with location (geography) type?
-- expect to see n_vp have values 1, 2, 3 for these 2 trips

SELECT * FROM fct_vp_dwell
