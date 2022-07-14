{{ config(materialized='table') }}

WITH stg_cleaned_device_transactions AS (

    SELECT DISTINCT
        * EXCEPT (
            calitp_file_name,
            calitp_n_dupes,
            calitp_n_dupe_ids,
            calitp_dupe_number,
            route_id,
            location_id),
        -- trim to align with gtfs cleaning steps
        -- since these fields are used to join with gtfs data
        trim(route_id) AS route_id,
        trim(location_id) AS location_id
    FROM {{ ref('stg_enriched_device_transactions') }}
    WHERE calitp_dupe_number = 1

)

SELECT * FROM stg_cleaned_device_transactions
