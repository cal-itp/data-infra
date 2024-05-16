WITH guideline_index AS (
    SELECT
        *,
        {{ url_remove_scheme(from_url_safe_base64('base64_url')) }} AS no_scheme_url,
        CASE
            WHEN check LIKE "%Mobility Database%" THEN 'mobility_database'
            WHEN check LIKE "%transit.land%" THEN 'transitland'
        END as aggregator
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check IN ({{ schedule_feed_on_transitland() }},
        {{ schedule_feed_on_mobility_database() }},
        {{ vehicle_positions_feed_on_transitland() }},
        {{ trip_updates_feed_on_transitland() }},
        {{ service_alerts_feed_on_transitland() }},
        {{ vehicle_positions_feed_on_mobility_database() }},
        {{ trip_updates_feed_on_mobility_database() }},
        {{ service_alerts_feed_on_mobility_database() }})
),

daily_scraped_urls AS (
    SELECT DISTINCT dt AS date,
           aggregator,
           feed_url_str,
           {{ url_remove_scheme('feed_url_str') }} AS no_scheme_url
    FROM {{ ref('stg_gtfs_quality__scraped_urls') }}
),

check_start AS (
    SELECT MIN(date) AS first_check_date
    FROM daily_scraped_urls
),

int_gtfs_quality__feed_aggregator AS (
    SELECT
        guideline_index.* EXCEPT(status, aggregator),
        first_check_date,
        CASE
        -- check that the row has the right entity + check combo, then assign statuses
            WHEN guideline_index.has_schedule_url
                AND check IN ({{ schedule_feed_on_transitland() }}, {{ schedule_feed_on_mobility_database() }})
                    THEN
                        CASE
                            WHEN daily_scraped_urls.aggregator IS NOT NULL THEN {{ guidelines_pass_status() }}
                            WHEN guideline_index.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                            WHEN daily_scraped_urls.aggregator IS NULL THEN {{ guidelines_fail_status() }}
                        END
            WHEN guideline_index.has_rt_url_tu
                AND check IN ({{ trip_updates_feed_on_transitland() }}, {{ trip_updates_feed_on_mobility_database() }})
                   THEN
                    CASE
                            WHEN daily_scraped_urls.aggregator IS NOT NULL THEN {{ guidelines_pass_status() }}
                            WHEN guideline_index.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                            WHEN daily_scraped_urls.aggregator IS NULL THEN {{ guidelines_fail_status() }}
                        END
            WHEN guideline_index.has_rt_url_vp
                AND check IN ({{ vehicle_positions_feed_on_transitland() }}, {{ vehicle_positions_feed_on_mobility_database() }})
                    THEN
                        CASE
                            WHEN daily_scraped_urls.aggregator IS NOT NULL THEN {{ guidelines_pass_status() }}
                            WHEN guideline_index.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                            WHEN daily_scraped_urls.aggregator IS NULL THEN {{ guidelines_fail_status() }}
                        END
            WHEN guideline_index.has_rt_url_sa
                AND check IN ({{ service_alerts_feed_on_transitland() }}, {{ service_alerts_feed_on_mobility_database() }})
                    THEN
                        CASE
                            WHEN daily_scraped_urls.aggregator IS NOT NULL THEN {{ guidelines_pass_status() }}
                            WHEN guideline_index.date < first_check_date THEN {{ guidelines_na_too_early_status() }}
                            WHEN daily_scraped_urls.aggregator IS NULL THEN {{ guidelines_fail_status() }}
                        END
            ELSE guideline_index.status
        END AS status,
        guideline_index.no_scheme_url AS idx_str_url,
        daily_scraped_urls.no_scheme_url AS agg_str_url,
        guideline_index.aggregator AS test_aggregator,
        daily_scraped_urls.aggregator
      FROM guideline_index
      CROSS JOIN check_start
      LEFT JOIN daily_scraped_urls
        ON guideline_index.no_scheme_url = daily_scraped_urls.no_scheme_url
        AND guideline_index.date = daily_scraped_urls.date
        AND guideline_index.aggregator = daily_scraped_urls.aggregator
)

SELECT * FROM int_gtfs_quality__feed_aggregator
