WITH guideline_index AS (
    SELECT
        *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check IN ({{ no_pb_error_vp() }},
        {{ no_pb_error_tu() }},
        {{ no_pb_error_sa() }})
),

fct_daily_rt_feed_files AS (
    SELECT * FROM {{ ref('fct_daily_rt_feed_files') }}
),

daily_success_percent AS (
    SELECT
        base64_url,
        date,
        feed_type,
        SUM(parse_success_file_count) * 100 / SUM(parse_success_file_count + parse_failure_file_count) AS percent_success
    FROM fct_daily_rt_feed_files
   GROUP BY 1, 2, 3
),

check_start AS (
    SELECT MIN(date) AS first_check_date
    FROM daily_success_percent
),

int_gtfs_quality__rt_protobuf_error AS (
    SELECT
        idx.* EXCEPT(status),
        first_check_date,
        percent_success,
        CASE
        -- check that the row has the right entity + check combo, then assign statuses
            WHEN (idx.has_rt_feed_tu AND check = {{ no_pb_error_tu() }})
                OR (idx.has_rt_feed_vp AND check = {{ no_pb_error_vp() }})
                OR (idx.has_rt_feed_sa AND check = {{ no_pb_error_sa() }})
                   THEN
                    CASE
                        WHEN percent_success >= 99 THEN {{ guidelines_pass_status() }}
                        WHEN idx.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN percent_success IS NULL THEN {{ guidelines_na_check_status() }}
                        WHEN percent_success < 99 THEN {{ guidelines_fail_status() }}
                    END
            ELSE idx.status
        END AS status,
      FROM guideline_index AS idx
      CROSS JOIN check_start
      LEFT JOIN daily_success_percent
        ON idx.date = daily_success_percent.date
        AND idx.base64_url = daily_success_percent.base64_url
)

SELECT * FROM int_gtfs_quality__rt_protobuf_error
