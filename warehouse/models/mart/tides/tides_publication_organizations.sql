{{
    config(
        materialized='view',
    )
}}

-- The TIDES reference-publication membership set: every organization that has
-- actually appeared in the published TIDES facts (via tides_publication_feeds).


SELECT DISTINCT organization_source_record_id
FROM {{ ref('tides_publication_feeds') }}
WHERE organization_source_record_id IS NOT NULL
