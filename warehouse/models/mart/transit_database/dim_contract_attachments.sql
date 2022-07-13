{{ config(materialized='table') }}

WITH latest AS (
    {{ get_latest_dense_rank(
        external_table = ref('stg_transit_database__contracts'),
        order_by = 'calitp_extracted_at DESC'
        ) }}
),


dim_contract_attachments AS (
    SELECT
        unnested_attachments.id AS key,
        latest.key AS contract_key,
        latest.name AS contract_name,
        unnested_attachments.url AS attachment_url,
        latest.calitp_extracted_at
    FROM latest,
        latest.attachments AS unnested_attachments
)

SELECT * FROM dim_contract_attachments
