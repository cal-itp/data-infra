{{ config(materialized='table') }}

WITH stg_transit_database__contracts AS (
    SELECT * FROM {{ ref('stg_transit_database__contracts') }}
),

dim_contract_attachments AS (
    SELECT
        unnested_attachments.id AS attachment_id,
        contract_id,
        contract_name,
        unnested_attachments.url AS attachment_url,
        calitp_extracted_at
    FROM stg_transit_database__contracts,
        stg_transit_database__contracts.attachments AS unnested_attachments
)

SELECT * FROM dim_contract_attachments
