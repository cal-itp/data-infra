WITH guideline_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ technical_contact_listed() }}
),

dim_feed_info AS (
    SELECT * FROM {{ ref('dim_feed_info') }}
),

files AS (
    SELECT * FROM {{ ref('fct_schedule_feed_files') }}
),

check_technical_contact AS (
    SELECT
        feed_key,
        LOGICAL_AND(feed_contact_email IS NOT NULL) AS has_contact
    FROM dim_feed_info
    GROUP BY 1
),

feed_has_feed_info AS (
    SELECT
        feed_key,
        LOGICAL_OR(gtfs_filename = "feed_info") AS has_feed_info
    FROM files
    GROUP BY 1
),

check_start AS (
    SELECT MIN(_feed_valid_from) AS first_check_date
    FROM dim_feed_info
),

int_gtfs_quality__technical_contact_listed AS (
    SELECT
        idx.* EXCEPT(status),
        CASE
            WHEN has_schedule_feed
                THEN
                    CASE
                        WHEN has_feed_info AND has_contact THEN {{ guidelines_pass_status() }}
                        -- TODO: could add special handling for April 16, 2021 (start of checks)
                        WHEN CAST(idx.date AS TIMESTAMP) < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN NOT has_feed_info OR NOT has_contact THEN {{ guidelines_fail_status() }}
                        WHEN has_feed_info IS NULL THEN {{ guidelines_na_check_status() }}
                    END
            ELSE idx.status
        END AS status
    FROM guideline_index idx
    CROSS JOIN check_start
    LEFT JOIN feed_has_feed_info
        ON idx.schedule_feed_key = feed_has_feed_info.feed_key
    LEFT JOIN check_technical_contact
        ON idx.schedule_feed_key = check_technical_contact.feed_key
)

SELECT * FROM int_gtfs_quality__technical_contact_listed
