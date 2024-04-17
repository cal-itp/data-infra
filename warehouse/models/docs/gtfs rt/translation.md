Original definitions from https://gtfs.org/realtime/reference/#message-translation

{% docs gtfs_translation__text %}
A UTF-8 string containing the message.
{% enddocs %}

{% docs gtfs_translation__language %}
BCP-47 language code. Can be omitted if the language is unknown or if no internationalization is done at all for the feed. At most one translation is allowed to have an unspecified language tag - if there is more than one translation, the language must be provided.
{% enddocs %}
