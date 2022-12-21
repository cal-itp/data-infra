{% macro transit_database_make_historical_dimension(
    once_daily_staging_table,
    date_col,
    record_id) %}

WITH once_daily_staging_table AS (
    SELECT *
    FROM {{ ref(once_daily_staging_table) }}
),

hashed AS (
    SELECT
        date_col AS dt,
        record_id AS key,
        MAX({{ date_col }}) OVER(PARTITION BY {{ record_id }} ORDER BY {{ date_col }} DESC) AS latest_extract,
        {{ dbt_utils.surrogate_key(
            dbt_utils.get_filtered_columns_in_relation(
                from=ref(once_daily_staging_table),
                except=[date_col]
            )
            ) }} AS content_hash
    FROM once_daily_staging_table
),

next_valid_extract AS (
    SELECT
        dt
        LEAD(dt) OVER (ORDER BY dt) AS next_dt
    FROM hashed
    GROUP BY dt
),

-- following: https://dba.stackexchange.com/questions/210907/determine-consecutive-occurrences-of-values
first_instances AS (
    SELECT
        hashed.dt,
        key,
        latest_extract,
        (DENSE_RANK() OVER (ORDER BY latest_extract DESC)) = 1 AS in_latest,
        next_dt,
        (LAG(content_hash) OVER (PARTITION BY key ORDER BY hashed.dt) != content_hash)
            OR (LAG(content_hash) OVER (PARTITION BY key ORDER BY hashed.dt) IS NULL) AS is_first
    FROM hashed
    LEFT JOIN next_valid_extract AS next
        ON hashed.latest_extract = next.ts
    QUALIFY is_first
),

all_versioned AS (
    SELECT
        key,
        dt AS _valid_from,
        CASE
            -- if there's a subsequent extract, use that extract time as end date
            WHEN LEAD(dt) OVER (PARTITION BY key ORDER BY dt) IS NOT NULL
                THEN {{ make_end_of_valid_range('LEAD(dt) OVER (PARTITION BY key ORDER BY dt)') }}
            ELSE
            -- if there's no subsequent extract, it was either deleted or it's current
            -- if it was in the latest extract, call it current (even if it errored)
            -- if it was not in the latest extract, call it deleted at the last time it was extracted
                CASE
                    WHEN in_latest THEN {{ make_end_of_valid_range('CAST("2099-01-01" AS TIMESTAMP)') }}
                    ELSE {{ make_end_of_valid_range('next_dt') }}
                END
        END AS _valid_to
    FROM first_instances
),

actual_data_only AS (
    SELECT
        dt,
        key,
        unzip_success,
        zipfile_extract_md5hash,
        _valid_from,
        _valid_to
    FROM all_versioned
    WHERE download_success AND unzip_success
),

final AS (
    SELECT
        {{ dbt_utils.surrogate_key(['key', '_valid_from']) }} AS key,
        {% for col in dbt_utils.get_filtered_columns_in_relation(
                from=ref(once_daily_staging_table),
                except=[date_col]
            ) %}
            col {% if not loop.last %}, {% endif %}
        {% endfor %}
        _valid_from,
        _valid_to
    FROM actual_data_only
)

SELECT * FROM final
{% endmacro %}
