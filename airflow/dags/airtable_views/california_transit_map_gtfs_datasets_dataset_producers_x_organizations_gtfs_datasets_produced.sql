---
operator: operators.SqlToWarehouseOperator

dst_table_name: views.airtable_california_transit_map_gtfs_datasets_dataset_producers_x_organizations_gtfs_datasets_produced

description: Mapping table for the GTFS gtfs_datasets table, dataset_producers column and the organizations table, gtfs_datasets_produced column in the California Transit Airtable base. Each row represents a relationship between a gtfs_datasets record and a organizations record.

fields:
  gtfs_dataset_id: Internal Airtable ID for a gtfs_datasets record
  organization_id: Internal Airtable ID for a organizations record
  gtfs_dataset_name: gtfs_datasets record name
  organization_name: organizations record name

tests:
  check_null:
    - gtfs_dataset_id
    - organization_id
    - gtfs_dataset_name
    - organization_name
  check_composite_unique:
    - gtfs_dataset_id
    - organization_id

external_dependencies:
  - airtable_loader: california_transit_gtfs_datasets
  - airtable_loader: california_transit_organizations
---

-- follow the sandbox example for unnesting airtable data

WITH
unnested_t1 AS (
    SELECT
        T1.gtfs_dataset_id
        , T1.name as gtfs_dataset_name
        , CAST(dataset_producers AS STRING) AS organization_id
    FROM
        `airtable.california_transit_gtfs_datasets` T1
        , UNNEST(JSON_VALUE_ARRAY(dataset_producers)) dataset_producers
),
unnested_t2 AS (
    SELECT
        T2.organization_id
        , T2.name as organization_name
        , CAST(gtfs_datasets_produced AS STRING) AS gtfs_dataset_id
    FROM
        `airtable.california_transit_organizations` T2
        , UNNEST(JSON_VALUE_ARRAY(gtfs_datasets_produced)) gtfs_datasets_produced
)

SELECT *
FROM unnested_t1
FULL OUTER JOIN unnested_t2 USING(gtfs_dataset_id, organization_id)
