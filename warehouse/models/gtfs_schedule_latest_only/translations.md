
{% docs gtfs_translations__table_name %}
Defines the table that contains the field to be translated. Allowed values are: agency, stops, routes, trips, stop_times, pathways, levels, feed_info and attributions (do not include the .txt file extension). If a table with a new file name is added by another proposal in the future, the table name is the name of the filename without the .txt file extension.
{% enddocs %}

{% docs gtfs_translations__field_name %}
Name of the field to be translated. Fields with type Text can be translated, fields with type URL, Email and Phone number can also be “translated” to provide resources in the correct language. Fields with other types should not be translated.
{% enddocs %}

{% docs gtfs_translations__language %}
Language of translation.

If the language is the same as in feed_info.feed_lang, the original value of the field will be assumed to be the default value to use in languages without specific translations (if default_lang doesn't specify otherwise).

Example: In Switzerland, a city in an officially bilingual canton is officially called “Biel/Bienne”, but would simply be called “Bienne” in French and “Biel” in German.
{% enddocs %}

{% docs gtfs_translations__translation %}
Translated value.
{% enddocs %}

{% docs gtfs_translations__record_id %}
Defines the record that corresponds to the field to be translated. The value in record_id should be a main ID of the table, as defined below:
• agency_id for agency.txt;
• stop_id for stops.txt;
• route_id for routes.txt;
• trip_id for trips.txt;
• trip_id for stop_times.txt;
• pathway_id for pathways.txt;
• level_id for levels.txt;
• attribution_id for attribution.txt.

No field should be translated in the other tables. However producers sometimes add extra fields that are outside the official specification and these unofficial fields may need to be translated. Below is the recommended way to use record_id for those tables:
• service_id for calendar.txt;
• service_id for calendar_dates.txt;
• fare_id for fare_attributes.txt;
• fare_id for fare_rules.txt;
• shape_id for shapes.txt;
• trip_id for frequencies.txt;
• from_stop_id for transfers.txt.

Conditionally Required:
- forbidden if table_name is feed_info;
- forbidden if field_value is defined;
- required if field_value is empty.
{% enddocs %}

{% docs gtfs_translations__record_sub_id %}
Helps the record that contains the field to be translated when the table doesn’t have a unique ID. Therefore, the value in record_sub_id is the secondary ID of the table, as defined by the table below:
• None for agency.txt;
• None for stops.txt;
• None for routes.txt;
• None for trips.txt;
• stop_sequence for stop_times.txt;
• None for pathways.txt;
• None for levels.txt;
• None for attributions.txt.

No field should be translated in the other tables. However producers sometimes add extra fields that are outside the official specification and these unofficial fields may need to be translated. Below is the recommended way to use record_sub_id for those tables:
• None for calendar.txt;
• date for calendar_dates.txt;
• None for fare_attributes.txt;
• route_id for fare_rules.txt;
• None for shapes.txt;
• start_time for frequencies.txt;
• to_stop_id for transfers.txt.

Conditionally Required:
- forbidden if table_name is feed_info;
- forbidden if field_value is defined;
- required if table_name=stop_times and record_id is defined.
{% enddocs %}

{% docs gtfs_translations__field_value %}
Instead of defining which record should be translated by using record_id and record_sub_id, this field can be used to define the value which should be translated. When used, the translation will be applied when the fields identified by table_name and field_name contains the exact same value defined in field_value.

The field must have exactly the value defined in field_value. If only a subset of the value matches field_value, the translation won’t be applied.

If two translation rules match the same record (one with field_value, and the other one with record_id), then the rule with record_id is the one which should be used.

Conditionally Required:
- forbidden if table_name is feed_info;
- forbidden if record_id is defined;
- required if record_id is empty.
{% enddocs %}
