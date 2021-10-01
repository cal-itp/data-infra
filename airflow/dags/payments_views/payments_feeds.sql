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
        (273, 0, 'sacrt'),
        (473, 0, 'clean-air-express')

    ]
    )
