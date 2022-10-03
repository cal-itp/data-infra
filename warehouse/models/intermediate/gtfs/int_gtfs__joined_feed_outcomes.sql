WITH stg_gtfs_schedule__download_outcomes AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__download_outcomes') }}
),

stg_gtfs_schedule__unzip_outcomes AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__unzip_outcomes') }}
),

int_gtfs__joined_feed_outcomes AS (
    SELECT
        d.ts,
        d.base64_url,
        d.config_extracted_at,
        d.download_success,
        d.download_exception,
        u.unzip_success,
        u.unzip_exception,
        u.zipfile_extract_md5hash,
        u.zipfile_files,
        u.zipfile_dirs
    FROM stg_gtfs_schedule__download_outcomes AS d
    LEFT JOIN stg_gtfs_schedule__unzip_outcomes AS u
        ON d.ts = u.ts
            AND d.base64_url = u.base64_url
)

SELECT * FROM int_gtfs__joined_feed_outcomes
