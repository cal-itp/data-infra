Original definitions from https://gtfs.org/schedule/reference/#fare_productstxt

{% docs gtfs_fare_products__fare_product_id %}
Identifies a fare product.
{% enddocs %}

{% docs gtfs_fare_products__fare_product_name %}
The name of the fare product as displayed to riders.
{% enddocs %}

{% docs gtfs_fare_products__fare_media_id %}
Identifies a fare media that can be employed to use the fare product during the trip. When fare_media_id is empty, it is considered that the fare media is unknown.
{% enddocs %}

{% docs gtfs_fare_products__amount %}
The cost of the fare product. May be negative to represent transfer discounts. May be zero to represent a fare product that is free.
{% enddocs %}

{% docs gtfs_fare_products__currency %}
The currency of the cost of the fare product.
{% enddocs %}
