WITH filter_by_sbmtd AS (

    SELECT *
    FROM {{ ref('payments_rides') }}
    WHERE
        participant_id = "sbmtd"

)

SELECT * FROM filter_by_sbmtd
