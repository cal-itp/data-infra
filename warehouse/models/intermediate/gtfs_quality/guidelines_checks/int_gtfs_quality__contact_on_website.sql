WITH guideline_index AS (
    SELECT *
    FROM {{ ref('int_gtfs_quality__guideline_checks_index') }}
    WHERE check = {{ organization_has_contact_info() }}
),

organizations AS (
    SELECT * FROM {{ ref('dim_organizations') }}
),

check_start AS (
    SELECT MIN(_valid_from) AS first_check_date
    FROM organizations
    WHERE manual_check__contact_on_website IS NOT NULL AND manual_check__contact_on_website != "Unknown"
),

int_gtfs_quality__contact_on_website AS (
    SELECT
        idx.* EXCEPT(status),
        orgs.manual_check__contact_on_website,
        first_check_date,
        CASE
        -- check that the row has the right entity + check combo, then assign statuses
            WHEN idx.has_organization
                   THEN
                    CASE
                        WHEN manual_check__contact_on_website = "Yes" THEN {{ guidelines_pass_status() }}
                        WHEN CAST(idx.date AS TIMESTAMP) < first_check_date THEN {{ guidelines_na_too_early_status() }}
                        WHEN manual_check__contact_on_website = "Unknown" OR manual_check__contact_on_website IS NULL THEN {{ guidelines_manual_check_needed_status() }}
                        WHEN manual_check__contact_on_website = "No" THEN {{ guidelines_fail_status() }}
                    END
            ELSE idx.status
        END AS status,
      FROM guideline_index AS idx
      CROSS JOIN check_start
      LEFT JOIN organizations AS orgs
        ON idx.organization_key = orgs.key
)

SELECT * FROM int_gtfs_quality__contact_on_website
