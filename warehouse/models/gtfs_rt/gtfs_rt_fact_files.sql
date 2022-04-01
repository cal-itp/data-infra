{% docs gtfs_rt_fact_files %}

Each row is a GTFS realtime file that was downloaded.
  Note that presence of a file is not a guarantee that the downloaded file is complete or valid.

{% enddocs %}

WITH source as (
    select *
    from {{ source('gtfs_rt_raw', 'calitp_files') }}
)

, gtfs_rt_fact_files as (
    SELECT
    calitp_extracted_at,
    calitp_itp_id,
    calitp_url_number,
    -- turn name from a file path like gtfs_rt_<file_type>_url
    -- to just file_type
    REGEXP_EXTRACT(name, r"gtfs_rt_(.*)_url") as name,
    size,
    md5_hash,
    DATE(calitp_extracted_at) as date_extracted,
    EXTRACT(HOUR from calitp_extracted_at) as hour_extracted,
    EXTRACT(MINUTE from calitp_extracted_at) as minute_extracted
    FROM source
)

SELECT * FROM gtfs_rt_fact_files
