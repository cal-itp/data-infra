Docs related to GTFS schedule pipeline outcomes

{% docs column_zipfile_md5_hash %}
MD5 hash for the zipfile being unzipped.
{% enddocs %}

{% docs column_zipfile_files %}
List (array) of filenames found inside the zipfile being unzipped.
{% enddocs %}

{% docs column_zipfile_dirs %}
List (array) of directories found inside the zipfile being unzipped.
If more than one directory is present, the zipfile is not valid for our pipeline.
{% enddocs %}

{% docs column_schedule_parse_success %}
Whether this file was parsed (from .txt to .json) successfully. False indicates file was not ingested and data will not be available.
{% enddocs %}

{% docs column_schedule_parse_exception %}
If parse_success is false, what exception was encountered in parsing.
{% enddocs %}

{% docs column_schedule_parse_filename %}
Filename within the original zipfile. Mostly for debugging. Use `gtfs_filename` column for most analysis.
{% enddocs %}

{% docs column_schedule_parse_feed_name %}
Feed name from GTFS download config.
Should not be used for joins.
{% enddocs %}

{% docs column_schedule_parse_feed_url %} Feed URL from GTFS download config.
Should not be used for joins.
{% enddocs %}

{% docs column_schedule_parse_original_filename %}
Full original filename from within zipfile; may contain a parent
directory name. Mostly for debugging. Use `gtfs_filename` for most analysis purposes.
{% enddocs %}

{% docs column_schedule_parse_gtfs_filename %}
The name of the GTFS file to which this data has been mapped.
This is guaranteed to be a file that is listed in the GTFS
spec at gtfs.org, for example "shapes".
This should be used for analysis and filtering.
{% enddocs %}

{% docs column_pct_sucesss %}
Successes as a percent of total files (`count_successes` / `count_files` * 100).
If this is a value less than 100, indicates that file conversion failed for some files in this feed.
{% enddocs %}
