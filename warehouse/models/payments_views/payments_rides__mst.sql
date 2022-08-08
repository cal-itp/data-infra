WITH filter_by_mst AS (

    SELECT *
    FROM {{ ref('payments_rides') }}
    WHERE
        participant_id = "mst"

)

SELECT * FROM filter_by_mst
