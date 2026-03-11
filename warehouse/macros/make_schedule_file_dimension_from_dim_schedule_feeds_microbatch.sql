{% macro make_schedule_file_dimension_from_dim_schedule_feeds_microbatch(dim_schedule_feeds, gtfs_file_table) %}

-- define feed file's feed_key, effective dates, & gtfs_dataset_key based on dim_schedule_feeds
SELECT
    t2.key AS feed_key,
    t2._valid_from AS _feed_valid_from,
    t2.feed_timezone,
    t1.*,
FROM {{ gtfs_file_table }} AS t1
INNER JOIN {{ dim_schedule_feeds }} AS t2
    ON t1.ts = t2._valid_from
    AND t1.base64_url = t2.base64_url

{% endmacro %}
