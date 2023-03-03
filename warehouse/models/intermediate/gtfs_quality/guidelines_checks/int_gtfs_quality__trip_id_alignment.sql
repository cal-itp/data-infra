{% set min_date_array = dbt_utils.get_column_values(table=ref('fct_daily_rt_feed_validation_notices'), column='date', order_by = 'date', max_records = 1) %}
{% set first_check_date = min_date_array[0] %}

WITH guideline_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ trip_id_alignment() }}
),

critical_notices AS (
    SELECT
        date,
        base64_url,
        COALESCE(SUM(total_notices), 0) AS errors,
    FROM {{ ref('fct_daily_rt_feed_validation_notices') }}
    -- Description for code E003:
    ---- "All trip_ids provided in the GTFS-rt feed must exist in the GTFS data, unless the schedule_relationship is ADDED"
    WHERE code = "E003"
    GROUP BY 1, 2
),

int_gtfs_quality__trip_id_alignment AS (
    SELECT
        idx.* EXCEPT(status),
        CASE
            WHEN has_rt_feed
                THEN
                    CASE
                        WHEN errors = 0 THEN {{ guidelines_pass_status() }}
                        WHEN errors > 0 THEN {{ guidelines_fail_status() }}
                        WHEN idx.date < '{{ first_check_date }}' THEN {{ guidelines_na_too_early_status() }}
                        WHEN errors IS NULL THEN {{ guidelines_na_check_status() }}
                    END
            ELSE idx.status
        END AS status
    FROM guideline_index AS idx
    LEFT JOIN critical_notices AS notices
    ON idx.date = notices.date
        AND idx.base64_url = notices.base64_url
)

SELECT * FROM int_gtfs_quality__trip_id_alignment
