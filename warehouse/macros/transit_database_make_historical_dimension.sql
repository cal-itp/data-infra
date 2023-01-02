{% macro transit_database_make_historical_dimension(
    once_daily_staging_table,
    date_col,
    record_id_col,
    array_cols = [],
    ignore_cols = []) %}

WITH safe_data AS (
    SELECT *
    {% if array_cols or ignore_cols %}
        EXCEPT(
            {% if array_cols %}
            {% for col in array_cols %}
            {{ col }} {% if not loop.last or ignore_cols %},{% endif %}
            {% endfor %}
            {% endif %}
            {% if ignore_cols %}
            {% for col in ignore_cols %}
            {{ col }} {% if not loop.last %},{% endif %}
            {% endfor %}
            {% endif %}
        )
    {% endif %}
    {% if array_cols %},
    {% for col in array_cols %}
        ARRAY_TO_STRING({{ col }}, '--') AS {{ col }} {% if not loop.last %},{% endif %}
    {% endfor %}
    {% endif %}
    FROM {{ ref(once_daily_staging_table) }}
),

hashed AS (
    SELECT
        {{ date_col }} AS dt,
        {{ record_id_col }} AS key,
        MAX({{ date_col }}) OVER(PARTITION BY {{ record_id_col }} ORDER BY {{ date_col }} DESC) AS latest_extract,
        {{ dbt_utils.surrogate_key(
            dbt_utils.get_filtered_columns_in_relation(
                from=ref(once_daily_staging_table),
                except=[date_col] + ignore_cols
            )
            ) }} AS content_hash
    FROM safe_data
),

next_valid_extract AS (
    SELECT
        dt,
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
        ON hashed.latest_extract = next.dt
    QUALIFY is_first
),

all_versioned AS (
    SELECT
        key,
        dt AS _valid_from,
        CASE
            -- if there's a subsequent extract, use that extract time as end date
            WHEN LEAD(dt) OVER (PARTITION BY key ORDER BY dt) IS NOT NULL
                THEN {{ make_end_of_valid_range('CAST(LEAD(dt) OVER (PARTITION BY key ORDER BY dt) AS TIMESTAMP)') }}
            ELSE
            -- if there's no subsequent extract, it was either deleted or it's current
            -- if it was in the latest extract, call it current (even if it errored)
            -- if it was not in the latest extract, call it deleted at the last time it was extracted
                CASE
                    WHEN in_latest THEN {{ make_end_of_valid_range('CAST("2099-01-01" AS TIMESTAMP)') }}
                    ELSE {{ make_end_of_valid_range('CAST(next_dt AS TIMESTAMP)') }}
                END
        END AS _valid_to
    FROM first_instances
),

final AS (
    SELECT
        all_versioned.* EXCEPT(key, _valid_from),
        CAST(_valid_from AS TIMESTAMP) AS _valid_from,
        orig.* EXCEPT({{ date_col }}
        {% if ignore_cols %}
        {% for col in ignore_cols %}
        , {{ col }} {% if not loop.last %},{% endif %}
        {% endfor %}
        {% endif %}
        ),
        _valid_to = {{ make_end_of_valid_range('CAST("2099-01-01" AS TIMESTAMP)') }} AS _is_current
    FROM all_versioned
    LEFT JOIN {{ ref(once_daily_staging_table) }} AS orig
    ON all_versioned._valid_from = orig.{{ date_col }}
    AND all_versioned.key = orig.{{ record_id_col }}

)

SELECT * FROM final
{% endmacro %}
