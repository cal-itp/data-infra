---
operator: operators.SqlToWarehouseOperator
dst_table_name: "views.payments_feeds"
---

SELECT *
FROM UNNEST(
    ARRAY<
        STRUCT<
            calitp_itp_id INT64,
            calitp_url_number INT64,
            participant_id STRING
        >
    > [

        (208, 0, 'mst'),
        (293, 0, 'sbmtd'),

        -- TODO: we need to double check the participant_ids below once we ingest
        -- their data
        (273, 0, 'sacrt'),
        (296, 0, 'scmtd')

    ]
    )
