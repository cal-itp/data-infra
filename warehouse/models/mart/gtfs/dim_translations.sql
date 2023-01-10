{{ config(enabled=False) }}
-- we do not actually process translations right now

WITH make_dim AS (
    {{ make_schedule_file_dimension_from_dim_schedule_feeds(
        ref('dim_schedule_feeds'),
        ref('stg_gtfs_schedule__translations'),
    ) }}
),

dim_translations AS (
    SELECT
        {{ dbt_utils.surrogate_key(['feed_key', 'table_name', 'field_name', 'language', 'record_id', 'record_sub_id', 'field_value']) }} AS key,
        feed_key,
        table_name,
        field_name,
        language,
        translation,
        record_id,
        record_sub_id,
        field_value,
        base64_url,
        _valid_from,
        _valid_to,
        _is_current
    FROM make_dim
)

SELECT * FROM dim_translations
