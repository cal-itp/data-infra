WITH payments_feeds AS (

    SELECT
        calitp_itp_id,
        calitp_url_number,
        participant_id
    FROM UNNEST(
        ARRAY<
            STRUCT<
                gtfs_dataset_key STRING,
                participant_id STRING
            >
        > [

            ('recysP9m9kjCJwHZe', 'mst'),
            ('rectQfIeiKDBeJSAV', 'sbmtd'),
            ('recbzZQUIdMmFvm1r', 'sacrt'),
            ('recLhUJUDjFXcmOte', 'clean-air-express')

        ]
        )
)

SELECT * FROM payments_feeds
