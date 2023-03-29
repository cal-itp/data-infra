WITH idx AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check IN ({{ feed_listed_schedule() }},
        {{ feed_listed_vp() }},
        {{ feed_listed_tu() }},
        {{ feed_listed_sa() }}
        )
),

dim_provider_gtfs_data AS (
    SELECT * FROM {{ ref('dim_provider_gtfs_data') }}
),

check_feeds AS (
    SELECT
        idx.service_key,
        idx.date,
        -- Some services are mapped to multiple associated_schedule_gtfs_dataset_key values at the same time.
        LOGICAL_OR(schedule_gtfs_dataset_key IS NOT NULL AND quartet.gtfs_service_data_customer_facing) AS service_has_schedule,
        LOGICAL_OR(trip_updates_gtfs_dataset_key IS NOT NULL AND quartet.gtfs_service_data_customer_facing) AS service_has_tu,
        LOGICAL_OR(service_alerts_gtfs_dataset_key IS NOT NULL AND quartet.gtfs_service_data_customer_facing) AS service_has_sa,
        LOGICAL_OR(vehicle_positions_gtfs_dataset_key IS NOT NULL AND quartet.gtfs_service_data_customer_facing) AS service_has_vp,
    FROM idx
    LEFT JOIN dim_provider_gtfs_data AS quartet
        ON idx.service_key = quartet.service_key
        AND CAST(idx.date AS TIMESTAMP) BETWEEN quartet._valid_from AND quartet._valid_to
    GROUP BY 1, 2
),

get_start AS (
    SELECT MIN(_valid_from) AS first_check_date
    FROM dim_provider_gtfs_data
),

int_gtfs_quality__feed_listed AS (
    SELECT
        idx.* EXCEPT(status),
        first_check_date,
        service_has_schedule,
        service_has_tu,
        service_has_vp,
        service_has_sa,
        CASE
        -- this is a tricky check: if a service is missing a given feed type,
        -- we want the failure to appear on all other feed type rows for that service (because there are no dedicated rows for the missing feed type)
        -- but if the service *has* the feed type, it should only appear on rows of that given type
            WHEN idx.has_service
                THEN
                    CASE
                        WHEN CAST(idx.date AS TIMESTAMP) < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        -- when the service has the given dataset type,
                        -- only put the pass on the actual customer-facing dataset itself
                        WHEN
                            (service_has_schedule AND check = {{ feed_listed_schedule() }})
                            OR (service_has_tu AND check = {{ feed_listed_tu() }})
                            OR (service_has_sa AND check = {{ feed_listed_sa() }})
                            OR (service_has_vp AND check = {{ feed_listed_vp() }})
                            THEN {{ guidelines_pass_status() }}

                        -- finally, if the service is *missing* the given dataset type, we list that on all rows associated with the service
                        WHEN
                            (NOT service_has_schedule AND check = {{ feed_listed_schedule() }})
                            OR (NOT service_has_tu AND check = {{ feed_listed_tu() }})
                            OR (NOT service_has_sa AND check = {{ feed_listed_sa() }})
                            OR (NOT service_has_vp AND check = {{ feed_listed_vp() }})
                            THEN {{ guidelines_fail_status() }}

                    END
            ELSE idx.status
        END AS status,
      FROM idx
      CROSS JOIN get_start
      LEFT JOIN check_feeds
        ON idx.service_key = check_feeds.service_key
        AND idx.date = check_feeds.date
)

SELECT * FROM int_gtfs_quality__feed_listed
