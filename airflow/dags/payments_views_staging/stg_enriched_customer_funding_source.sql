---
operator: operators.SqlToWarehouseOperator
dst_table_name: "payments.stg_enriched_customer_funding_source"

external_dependencies:
  - payments_loader: all
---

WITH

core_enrichments AS (
    {{

      sql_enrich_duplicates(
        "payments.customer_funding_source",
        ["funding_source_id"],
        ["calitp_file_name desc"]
      )

    }}
),

enrichments_with_ordered_ids AS (
    SELECT
        *,

        COUNT(DISTINCT calitp_hash) OVER (
            PARTITION BY funding_source_id, calitp_export_datetime) AS calitp_funding_source_id_ranking_size,
        DENSE_RANK() OVER (
            PARTITION BY funding_source_id
            ORDER BY calitp_export_datetime DESC) AS calitp_funding_source_id_rank,

        COUNT(DISTINCT calitp_hash) OVER (
            PARTITION BY funding_source_vault_id, calitp_export_datetime) AS calitp_funding_source_vault_id_ranking_size,
        DENSE_RANK() OVER (
            PARTITION BY funding_source_vault_id
            ORDER BY calitp_export_datetime DESC) AS calitp_funding_source_vault_id_rank,

        COUNT(DISTINCT calitp_hash) OVER (
            PARTITION BY customer_id, calitp_export_datetime) AS calitp_customer_id_ranking_size,
        DENSE_RANK() OVER (
            PARTITION BY customer_id
            ORDER BY calitp_export_datetime DESC) AS calitp_customer_id_rank

    FROM core_enrichments
)

SELECT *
FROM enrichments_with_ordered_ids
