{{ config(materialized='table') }}

WITH files_of_interest AS (
    SELECT
        filename,
        gtfs_filename,
        reason
    FROM UNNEST(
        ARRAY<
            STRUCT<
                filename STRING,
                gtfs_filename STRING,
                reason STRING
            >
        > [
            ('shapes.txt', 'shapes', 'Visual display'),
            ('levels.txt', 'levels', 'Navigation'),
            ('pathways.txt', 'pathways', 'Navigation'),
            ('fare_leg_rules.txt', 'fare_leg_rules', 'Fares'),
            ('fare_rules.txt', 'fare_rules', 'Fares'),
            ('feed_info.txt', 'feed_info', 'Technical contacts')
        ]
        )
),

files AS (
    SELECT
        *,
        TRUE as file_present
    FROM {{ ref('fct_schedule_feed_files') }}
    -- we only want one extract per feed per day, take the latest one
    QUALIFY DENSE_RANK() OVER (PARTITION BY feed_key, EXTRACT(DATE FROM ts) ORDER BY ts DESC) = 1
),

idx_monthly_reports_site AS (
    SELECT *
    FROM {{ ref('idx_monthly_reports_site') }}
),

int_gtfs__organization_dataset_map AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__organization_dataset_map') }}
    WHERE gtfs_dataset_type = "schedule"
),

generate_biweekly_dates AS (
    SELECT DISTINCT
        publish_date,
        sample_dates
    FROM idx_monthly_reports_site
    LEFT JOIN
        UNNEST(GENERATE_DATE_ARRAY(
            -- add a few days because otherwise it will always pick the first of the month,
            -- which may be disproportionately likely to have new feed published and thus issues
            DATE_ADD(CAST(date_start AS DATE), INTERVAL 3 DAY),
            CAST(date_end AS DATE), INTERVAL 2 WEEK)) AS sample_dates
),

fct_monthly_reports_site_organization_file_checks AS (
    SELECT
        {{ dbt_utils.generate_surrogate_key(['idx.publish_date',
            'idx.organization_source_record_id',
            'dates.sample_dates',
            'files_of_interest.filename']) }} AS key,
        idx.organization_name,
        dates.sample_dates AS date_checked,
        idx.organization_source_record_id,
        idx.organization_itp_id,
        idx.publish_date,
        files_of_interest.filename,
        files_of_interest.gtfs_filename,
        files_of_interest.reason,
        LOGICAL_AND(COALESCE(file_present, FALSE)) AS file_present
    FROM idx_monthly_reports_site AS idx
    LEFT JOIN generate_biweekly_dates AS dates
        USING (publish_date)
    LEFT JOIN int_gtfs__organization_dataset_map AS map
        ON dates.sample_dates = map.date
        AND idx.organization_source_record_id = map.organization_source_record_id
    CROSS JOIN files_of_interest
    LEFT JOIN files
        ON map.schedule_feed_key = files.feed_key
        AND map.date = EXTRACT(DATE FROM files.ts)
        AND files.gtfs_filename = files_of_interest.gtfs_filename
    GROUP BY 1, 2, 3, 4, 5, 6, 7, 8, 9
)

SELECT * FROM fct_monthly_reports_site_organization_file_checks
