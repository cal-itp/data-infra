WITH

idx AS (
    SELECT * FROM {{ ref('int_gtfs_quality__organization_guideline_index') }}
),

organizations AS (
    SELECT * FROM {{ ref('dim_organizations') }}
),

int_gtfs_quality__contact_on_website AS (
    SELECT
        idx.date,
        idx.organization_key,
        -- TODO: use real macros
        'Organization has contact info on website' AS check,
        'Has contact info' AS feature,
        CASE manual_check__contact_on_website
            WHEN 'Yes' then 'PASS'
        END AS status,
    FROM idx
    LEFT JOIN organizations
        ON idx.organization_key = organizations.key
)

SELECT * FROM int_gtfs_quality__contact_on_website
