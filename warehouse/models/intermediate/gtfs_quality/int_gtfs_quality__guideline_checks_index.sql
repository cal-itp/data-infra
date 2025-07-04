{{ config(materialized='table', cluster_by='check') }}

WITH checks AS (
    SELECT *
    FROM {{ ref('stg_gtfs_quality__intended_checks') }}
),

assessment_candidates AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__daily_assessment_candidate_entities') }}
),

cross_join AS (
    SELECT
        key,
        date,
        organization_name,
        service_name,
        gtfs_dataset_name,
        gtfs_dataset_type,
        check,
        feature,
        entity,
        is_manual,
        reports_order,

        organization_source_record_id,
        service_source_record_id,
        gtfs_service_data_source_record_id,
        gtfs_dataset_source_record_id,

        public_customer_facing_fixed_route,
        public_customer_facing_or_regional_subfeed_fixed_route,
        organization_assessed,
        service_assessed,
        gtfs_service_data_assessed,

        organization_itp_id,
        organization_hubspot_company_record_id,
        organization_ntd_id,

        gtfs_service_data_customer_facing,
        gtfs_service_data_category,
        regional_feed_type,
        backdated_regional_feed_type,
        use_subfeed_for_reports,
        gtfs_dataset_deprecated_date,

        base64_url,
        had_rt_files,

        organization_key,
        service_key,
        gtfs_service_data_key,
        gtfs_dataset_key,
        schedule_feed_key,
        schedule_to_use_for_rt_validation_gtfs_dataset_key,

        COALESCE((gtfs_dataset_type = "schedule" AND gtfs_dataset_key IS NOT NULL AND gtfs_dataset_deprecated_date IS NULL), FALSE) AS has_gtfs_dataset_schedule,
        COALESCE((gtfs_dataset_type = "schedule" AND base64_url IS NOT NULL AND gtfs_dataset_deprecated_date IS NULL), FALSE) AS has_schedule_url,
        schedule_feed_key IS NOT NULL AS has_schedule_feed,

        had_rt_files AS has_rt_feed,

        COALESCE((gtfs_dataset_type = "vehicle_positions" AND gtfs_dataset_key IS NOT NULL AND gtfs_dataset_deprecated_date IS NULL), FALSE) AS has_gtfs_dataset_vp,
        COALESCE((gtfs_dataset_type = "vehicle_positions" AND base64_url IS NOT NULL AND gtfs_dataset_deprecated_date IS NULL), FALSE) AS has_rt_url_vp,
        COALESCE((gtfs_dataset_type = "vehicle_positions" AND had_rt_files), FALSE) AS has_rt_feed_vp,

        COALESCE((gtfs_dataset_type = "trip_updates" AND gtfs_dataset_key IS NOT NULL AND gtfs_dataset_deprecated_date IS NULL), FALSE) AS has_gtfs_dataset_tu,
        COALESCE((gtfs_dataset_type = "trip_updates" AND base64_url IS NOT NULL AND  gtfs_dataset_deprecated_date IS NULL), FALSE) AS has_rt_url_tu,
        COALESCE((gtfs_dataset_type = "trip_updates" AND had_rt_files), FALSE) AS has_rt_feed_tu,

        COALESCE((gtfs_dataset_type = "service_alerts" AND gtfs_dataset_key IS NOT NULL AND gtfs_dataset_deprecated_date IS NULL), FALSE) AS has_gtfs_dataset_sa,
        COALESCE((gtfs_dataset_type = "service_alerts" AND base64_url IS NOT NULL AND gtfs_dataset_deprecated_date IS NULL), FALSE) AS has_rt_url_sa,
        COALESCE((gtfs_dataset_type = "service_alerts" AND had_rt_files), FALSE) AS has_rt_feed_sa,

        organization_key IS NOT NULL AS has_organization,
        service_key IS NOT NULL AS has_service,
        COALESCE((gtfs_service_data_key IS NOT NULL AND gtfs_dataset_type = "schedule"), FALSE) AS has_gtfs_service_data_schedule

    FROM assessment_candidates
    CROSS JOIN checks
),

int_gtfs_quality__guideline_checks_index AS (
    SELECT
        key,
        date,
        organization_name,
        service_name,
        gtfs_dataset_name,
        gtfs_dataset_type,
        check,
        feature,
        entity,
        is_manual,
        reports_order,

        organization_source_record_id,
        service_source_record_id,
        gtfs_service_data_source_record_id,
        gtfs_dataset_source_record_id,

        public_customer_facing_fixed_route,
        public_customer_facing_or_regional_subfeed_fixed_route,
        organization_assessed,
        service_assessed,
        gtfs_service_data_assessed,

        organization_itp_id,
        organization_hubspot_company_record_id,
        organization_ntd_id,

        gtfs_service_data_customer_facing,
        gtfs_service_data_category,
        regional_feed_type,
        backdated_regional_feed_type,
        use_subfeed_for_reports,
        gtfs_dataset_deprecated_date,

        base64_url,
        had_rt_files,

        has_gtfs_dataset_schedule,
        has_schedule_url,
        has_schedule_feed,

        has_rt_feed,

        has_gtfs_dataset_vp,
        has_rt_url_vp,
        has_rt_feed_vp,

        has_gtfs_dataset_tu,
        has_rt_url_tu,
        has_rt_feed_tu,

        has_gtfs_dataset_sa,
        has_rt_url_sa,
        has_rt_feed_sa,

        has_organization,
        has_service,
        has_gtfs_service_data_schedule,

        CASE
            WHEN (entity = {{ gtfs_dataset_schedule() }} AND NOT has_gtfs_dataset_schedule)
                OR (entity = {{ schedule_feed() }} AND NOT has_schedule_feed)
                OR (entity = {{ schedule_url() }} AND NOT has_schedule_url)
                OR (entity = {{ gtfs_dataset_vp() }} AND NOT has_gtfs_dataset_vp)
                OR (entity = {{ rt_url_vp() }} AND NOT has_rt_url_vp)
                OR (entity = {{ rt_feed_vp() }} AND NOT has_rt_feed_vp)
                OR (entity = {{ gtfs_dataset_tu() }} AND NOT has_gtfs_dataset_tu)
                OR (entity = {{ rt_url_tu() }} AND NOT has_rt_url_tu)
                OR (entity = {{ rt_feed_tu() }} AND NOT has_rt_feed_tu)
                OR (entity = {{ gtfs_dataset_sa() }} AND NOT has_gtfs_dataset_sa)
                OR (entity = {{ rt_url_sa() }} AND NOT has_rt_url_sa)
                OR (entity = {{ rt_feed_sa() }} AND NOT has_rt_feed_sa)
                OR (entity = {{ rt_feed() }} AND NOT has_rt_feed)
                OR (entity = {{ organization() }} AND NOT has_organization)
                OR (entity = {{ service() }} AND NOT has_service)
                OR (entity = {{ gtfs_service_data_schedule() }} AND NOT has_gtfs_service_data_schedule)
                THEN {{ guidelines_na_entity_status() }}
            ELSE {{ guidelines_to_be_assessed_status() }}
        END AS status,

        CASE
            WHEN (check ='Includes wheelchair_accessible in trips.txt'
            OR
            check = 'Includes wheelchair_boarding in stops.txt')
                THEN 0
        END AS percentage,

        organization_key,
        service_key,
        gtfs_service_data_key,
        gtfs_dataset_key,
        schedule_feed_key,
        schedule_to_use_for_rt_validation_gtfs_dataset_key
    FROM cross_join
)

SELECT * FROM int_gtfs_quality__guideline_checks_index
