---
operator: operators.SqlToWarehouseOperator

dst_table_name: sandbox.airtable_denormalized

dependencies:
  - load_airflow_child
---

WITH

unnested_parent AS (
    SELECT
        T1.* EXCEPT(child_id)
        , CAST(child_id AS STRING) AS child_id
    FROM
        `sandbox.airtable_parent` T1
        , UNNEST(JSON_VALUE_ARRAY(child_id)) child_id
)

SELECT *
FROM unnested_parent
LEFT JOIN `sandbox.airtable_child` USING (child_id)
