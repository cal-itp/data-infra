WITH

v3 AS (
    SELECT * FROM {{ ref('gtfs_schedule_validation_code_descriptions_v3_1_1') }}
),

v4 AS (
    SELECT * FROM {{ ref('gtfs_schedule_validation_code_descriptions_v4_0_0') }}
),

stg_gtfs_quality__schedule_validation_code_descriptions AS (
    SELECT
        `type` AS severity,
        Name AS code,
        Human_Readable_Description AS description,
        'v3.1.1' AS gtfs_validator_version, -- this has to match what's in the validator Dockerfile
    FROM v3

    UNION ALL

    SELECT
        `type` AS severity,
        Name AS code,
        Human_Readable_Description AS description,
        'v4.0.0' AS gtfs_validator_version, -- this has to match what's in the validator Dockerfile
    FROM v4
)

SELECT * FROM stg_gtfs_quality__schedule_validation_code_descriptions
