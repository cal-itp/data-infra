Docs macros that apply to GTFS schedule data only

{% docs column_schedule_calitp_extracted_at %}

The date that the schedule data was downloaded

{% enddocs %}

{% docs column_schedule_calitp_deleted_at %}

The date that the schedule data was deleted; data can be deleted because a new version becomes available (rendering the prior version obsolete) or because we stop scraping it entirely, for example because the agency is no longer operating services. The value "2099-01-01" indicates that the row has not yet been deleted and is still active

{% enddocs %}

{% docs column_schedule_calitp_hash %}

Hashed value of all GTFS columns plus calitp_itp_id and calitp_url_number (i.e., unversioned hash)

{% enddocs %}

{% docs column_schedule_key %}

Hashed value of all GTFS columns plus calitp_itp_id, calitp_url_number, and calitp_extracted_at (i.e., versioned hash)

{% enddocs %}

{% docs column_schedule_file_key %}

GTFS file name (like "agency.txt")

{% enddocs %}
