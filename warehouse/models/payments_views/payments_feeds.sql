WITH payments_feeds AS (

    SELECT
        gtfs_dataset_source_record_id,
        participant_id
    FROM UNNEST(
        ARRAY<
            STRUCT<
                gtfs_dataset_source_record_id STRING,
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
