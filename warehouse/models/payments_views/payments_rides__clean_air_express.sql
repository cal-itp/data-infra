WITH filter_by_clean_air_express AS (

    SELECT *
    FROM {{ ref('payments_rides') }}
    WHERE
        participant_id = "clean-air-express"

)

SELECT * FROM filter_by_clean_air_express
