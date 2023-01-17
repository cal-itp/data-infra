{{ config(materialized='table') }}

-- TODO: add handling for back-dating mappings before the GTFS dataset record was created

WITH gtfs_datasets AS (
    SELECT *
    FROM {{ ref('dim_gtfs_datasets') }}
    WHERE base64_url IS NOT NULL
),

latest_appearance AS (
    SELECT
        base64_url,
        MAX(_valid_to) AS latest_app
    FROM gtfs_datasets
    GROUP BY base64_url
),

int_transit_database__urls_to_gtfs_datasets AS (
    SELECT
        gtfs_datasets.base64_url,
        gtfs_datasets.original_record_id,
        gtfs_datasets.key AS gtfs_dataset_key,
        GREATEST(gtfs_datasets._valid_from, COALESCE(self._valid_from, '1900-01-01')) AS _valid_from,
        LEAST(gtfs_datasets._valid_to, COALESCE(self._valid_to, '2099-01-01')) AS _valid_to
    FROM gtfs_datasets
    LEFT JOIN latest_appearance
        USING (base64_url)
    LEFT JOIN gtfs_datasets AS self
        ON gtfs_datasets.base64_url = self.base64_url
        AND gtfs_datasets._valid_from < self._valid_to
        AND gtfs_datasets._valid_to > self._valid_from
        AND gtfs_datasets.original_record_id != self.original_record_id
    LEFT JOIN gtfs_datasets AS latest
        ON gtfs_datasets.base64_url = latest.base64_url
        AND latest_appearance.latest_app = latest._valid_to
    WHERE self.key IS NULL OR gtfs_datasets.original_record_id = latest.original_record_id
)

SELECT * FROM int_transit_database__urls_to_gtfs_datasets
