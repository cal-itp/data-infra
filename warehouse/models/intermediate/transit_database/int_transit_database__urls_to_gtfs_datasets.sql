{{ config(materialized='table') }}

-- TODO: add handling for back-dating mappings before the GTFS dataset record was created

WITH gtfs_datasets AS (
    SELECT *
    FROM {{ ref('dim_gtfs_datasets') }}
    WHERE base64_url IS NOT NULL
),

appearance_duration AS (
    SELECT
        base64_url,
        MAX(_valid_to) AS latest_app,
        MIN(_valid_from) AS first_app
    FROM gtfs_datasets
    GROUP BY base64_url
),

int_transit_database__urls_to_gtfs_datasets AS (
    SELECT
        gtfs_datasets.base64_url,
        gtfs_datasets.source_record_id,
        gtfs_datasets.key AS gtfs_dataset_key,
        CASE
            WHEN gtfs_datasets._valid_from = appearance_duration.first_app THEN CAST('1900-01-01' AS TIMESTAMP)
            ELSE gtfs_datasets._valid_from
        END AS _valid_from,
        gtfs_datasets._valid_to
    FROM gtfs_datasets
    LEFT JOIN appearance_duration
        USING (base64_url)
    LEFT JOIN gtfs_datasets AS self
        ON gtfs_datasets.base64_url = self.base64_url
        AND gtfs_datasets._valid_from < self._valid_to
        AND gtfs_datasets._valid_to > self._valid_from
        AND gtfs_datasets.source_record_id != self.source_record_id
    LEFT JOIN gtfs_datasets AS latest
        ON gtfs_datasets.base64_url = latest.base64_url
        AND appearance_duration.latest_app = latest._valid_to
    WHERE self.key IS NULL OR gtfs_datasets.source_record_id = latest.source_record_id
)

SELECT * FROM int_transit_database__urls_to_gtfs_datasets
