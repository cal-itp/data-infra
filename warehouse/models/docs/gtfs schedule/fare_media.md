Original definitions from https://gtfs.org/reference/static#fare_mediatxt

{% docs gtfs_fare_media__fare_media_id %}
Identifies a fare media.
{% enddocs %}

{% docs gtfs_fare_media__fare_media_name %}
Name of the fare media.

For fare media which are transit cards (fare_media_type =2) or mobile apps (fare_media_type =4), the fare_media_name should be included and should match the rider-facing name used by the organizations delivering them.
{% enddocs %}

{% docs gtfs_fare_media__fare_media_type %}
The type of fare media. Valid options are:

0 - None. Used when there is no fare media involved in purchasing or validating a fare product, such as paying cash to a driver or conductor with no physical ticket provided.
2 - Physical transit card that has stored tickets, passes or monetary value.
3 - cEMV (contactless Europay, Mastercard and Visa) as an open-loop token container for account-based ticketing.
4 - Mobile app that have stored virtual transit cards, tickets, passes, or monetary value.
{% enddocs %}
