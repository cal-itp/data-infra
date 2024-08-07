Docs macros that apply across several domains

{% docs column_valid_from %}
Starting timestamp (inclusive) from which this record is valid.
{% enddocs %}

{% docs column_valid_to %}
Ending timestamp (inclusive) through which this record is valid.
{% enddocs %}

{% docs column_is_current %}
Boolean indicating whether a record is among the latest set (used in open data publishing).
{% enddocs %}

{% docs column_download_success %}
Boolean indicating whether this download attempt was successful.
{% enddocs %}

{% docs column_unzip_success %}
Boolean indicating whether this unzip attempt was successful.
{% enddocs %}

{% docs column_download_exception %}
If download attempt failed, lists the exception that was encountered.
{% enddocs %}

{% docs column_unzip_exception %}
If unzip attempt failed, lists the exception that was encountered.
{% enddocs %}

{% docs column_base64_url %}
Base 64 encoded URL from which this data was scraped.
{% enddocs %}
