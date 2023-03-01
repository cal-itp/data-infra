WITH

idx AS (
    SELECT * FROM {{ ref('int_gtfs_quality__services_guideline_index') }}
),

dim_provider_gtfs_data AS (
    SELECT * FROM {{ ref('dim_provider_gtfs_data') }}
),

joined AS (
    SELECT
        idx.date,
        idx.service_key,
        -- Some services are mapped to multiple service_alerts_gtfs_dataset_key values at the same time.
        -- This is one way to address that, open to better solutions!
        ANY_VALUE(service_alerts_gtfs_dataset_key) AS gtfs_dataset_key
    FROM idx
    LEFT JOIN dim_provider_gtfs_data AS quartet
        ON idx.service_key = quartet.service_key
       AND TIMESTAMP(idx.date) BETWEEN quartet._valid_from AND quartet._valid_to
       AND quartet.customer_facing
    GROUP BY 1,2
),

int_gtfs_quality__feed_listed_sa AS (
    SELECT
        date,
        service_key,
        {{ feed_listed_sa() }} AS check,
        {{ compliance_rt() }} AS feature,
        CASE WHEN gtfs_dataset_key IS NOT null THEN {{ guidelines_pass_status() }}
             ELSE {{ guidelines_fail_status() }}
        END AS status,
    FROM joined
)

SELECT * FROM int_gtfs_quality__feed_listed_sa
