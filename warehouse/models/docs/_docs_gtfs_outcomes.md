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
