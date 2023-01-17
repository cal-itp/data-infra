WITH stg_gtfs_schedule__download_outcomes AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__download_outcomes') }}
),

stg_gtfs_schedule__unzip_outcomes AS (
    SELECT *
    FROM {{ ref('stg_gtfs_schedule__unzip_outcomes') }}
),

int_gtfs_schedule__grouped_feed_file_parse_outcomes AS (
    SELECT *
    FROM {{ ref('int_gtfs_schedule__grouped_feed_file_parse_outcomes') }}
),

urls_to_gtfs_datasets AS (
    SELECT * FROM {{ ref('int_transit_database__urls_to_gtfs_datasets') }}
),


join_outcomes_only AS (
    SELECT
        d.ts,
        d.base64_url,
        d._config_extract_ts,
        d.download_success,
        d.download_exception,
        JSON_VALUE(d.download_response_headers, '$."Last-Modified"') AS last_modified_string,
        u.unzip_success,
        u.unzip_exception,
        u.zipfile_extract_md5hash,
        u.zipfile_files,
        u.zipfile_dirs,
        p.pct_success AS pct_files_successfully_parsed
    FROM stg_gtfs_schedule__download_outcomes AS d
    LEFT JOIN stg_gtfs_schedule__unzip_outcomes AS u
        ON d.ts = u.ts
            AND d.base64_url = u.base64_url
    LEFT JOIN int_gtfs_schedule__grouped_feed_file_parse_outcomes AS p
        ON d.ts = p.ts
            AND d.base64_url = p.base64_url
),

int_gtfs_schedule__joined_feed_outcomes AS (
    SELECT
        urls_to_gtfs_datasets.gtfs_dataset_key,
        f.ts,
        f.base64_url,
        f._config_extract_ts,
        f.download_success,
        f.download_exception,
        -- this seems to be a standard format? https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Last-Modified#syntax
        -- Last-Modified: <day-name>, <day> <month> <year> <hour>:<minute>:<second> GMT
        -- but there are some non-standard rows
        CASE WHEN last_modified_string like '%GMT' THEN PARSE_TIMESTAMP("%a, %d %b %Y %H:%M:%S GMT", last_modified_string)
             -- 1/28/2020 6:29:01 PM
             WHEN last_modified_string like '%PM' THEN PARSE_TIMESTAMP("%m/%d/%Y %I:%M:%S %p", last_modified_string)
        END AS last_modified_timestamp,
        f.unzip_success,
        f.unzip_exception,
        f.zipfile_extract_md5hash,
        f.zipfile_files,
        f.zipfile_dirs,
        f.pct_files_successfully_parsed
    FROM join_outcomes_only AS f
    LEFT JOIN urls_to_gtfs_datasets
        ON f.base64_url = urls_to_gtfs_datasets.base64_url
        AND f.ts BETWEEN urls_to_gtfs_datasets._valid_from AND urls_to_gtfs_datasets._valid_to
)

SELECT * FROM int_gtfs_schedule__joined_feed_outcomes
