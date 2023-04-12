WITH stg_cleaned_device_transactions AS (

    SELECT DISTINCT
        * EXCEPT (
            calitp_file_name,
            calitp_n_dupes,
            calitp_n_dupe_ids,
            calitp_dupe_number,
            route_id,
            location_id,
            longitude,
            latitude),

        -- cast lng/lat to float fields
        CAST(longitude AS NUMERIC) AS longitude,
        CAST(latitude AS NUMERIC) AS latitude,

        -- trim to align with gtfs cleaning steps
        -- since these fields are used to join with gtfs data
        TRIM(route_id) AS route_id,
        TRIM(location_id) AS location_id
    FROM {{ ref('stg_enriched_device_transactions') }}
    WHERE calitp_dupe_number = 1

)

SELECT
    *,
    ST_GEOGPOINT(longitude, latitude) AS geography
FROM stg_cleaned_device_transactions
