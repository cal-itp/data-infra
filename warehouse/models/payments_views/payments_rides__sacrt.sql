WITH filter_by_sacrt AS (

    SELECT *
    FROM {{ ref('payments_rides') }}
    WHERE
        participant_id = "sacrt"

)

SELECT * FROM filter_by_sacrt
