WITH

source AS (
    SELECT * FROM {{ ref('gtfs_rt_validation_code_descriptions') }}
),

stg_gtfs_quality__rt_validation_code_descriptions AS (
    SELECT
        code,
        description,
        COALESCE(is_critical = 'y', false) AS is_critical,
   FROM source
)

SELECT * FROM stg_gtfs_quality__rt_validation_code_descriptions
