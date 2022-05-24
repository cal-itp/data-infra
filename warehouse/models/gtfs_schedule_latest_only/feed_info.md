Original definitions from https://gtfs.org/reference/static#feed_infotxt

{% docs gtfs_feed_info__feed_publisher_name %}
Full name of the organization that publishes the dataset. This may be the same as one of the agency.agency_name values.
{% enddocs %}

{% docs gtfs_feed_info__feed_publisher_url %}
URL of the dataset publishing organization's website. This may be the same as one of the agency.agency_url values.
{% enddocs %}

{% docs gtfs_feed_info__feed_lang %}
Default language used for the text in this dataset. This setting helps GTFS consumers choose capitalization rules and other language-specific settings for the dataset. The file translations.txt can be used if the text needs to be translated into languages other than the default one.

The default language may be multilingual for datasets with the original text in multiple languages. In such cases, the feed_lang field should contain the language code mul defined by the norm ISO 639-2. The best practice here would be to provide, in translations.txt, a translation for each language used throughout the dataset. If all the original text in the dataset is in the same language, then mul should not be used.Example: Consider a dataset from a multilingual country like Switzerland, with the original stops.stop_name field populated with stop names in different languages. Each stop name is written according to the dominant language in that stop’s geographic location, e.g. Genève for the French-speaking city of Geneva, Zürich for the German-speaking city of Zurich, and Biel/Bienne for the bilingual city of Biel/Bienne. The dataset feed_lang should be mul and translations would be provided in translations.txt, in German: Genf, Zürich and Biel; in French: Genève, Zurich and Bienne; in Italian: Ginevra, Zurigo and Bienna; and in English: Geneva, Zurich and Biel/Bienne.
{% enddocs %}

{% docs gtfs_feed_info__default_lang %}
Defines the language that should be used when the data consumer doesn’t know the language of the rider. It will often be en (English).
{% enddocs %}

{% docs gtfs_feed_info__feed_start_date %}
The dataset provides complete and reliable schedule information for service in the period from the beginning of the feed_start_date day to the end of the feed_end_date day. Both days can be left empty if unavailable. The feed_end_date date must not precede the feed_start_date date if both are given. Dataset providers are encouraged to give schedule data outside this period to advise of likely future service, but dataset consumers should treat it mindful of its non-authoritative status. If feed_start_date or feed_end_date extend beyond the active calendar dates defined in calendar.txt and calendar_dates.txt, the dataset is making an explicit assertion that there is no service for dates within the feed_start_date or feed_end_date range but not included in the active calendar dates.
{% enddocs %}

{% docs gtfs_feed_info__feed_end_date %}
(see above)
{% enddocs %}

{% docs gtfs_feed_info__feed_version %}
String that indicates the current version of their GTFS dataset. GTFS-consuming applications can display this value to help dataset publishers determine whether the latest dataset has been incorporated.
{% enddocs %}

{% docs gtfs_feed_info__feed_contact_email %}
Email address for communication regarding the GTFS dataset and data publishing practices. feed_contact_email is a technical contact for GTFS-consuming applications. Provide customer service contact information through agency.txt.
{% enddocs %}

{% docs gtfs_feed_info__feed_contact_url %}
URL for contact information, a web-form, support desk, or other tools for communication regarding the GTFS dataset and data publishing practices. feed_contact_url is a technical contact for GTFS-consuming applications. Provide customer service contact information through agency.txt.
{% enddocs %}
