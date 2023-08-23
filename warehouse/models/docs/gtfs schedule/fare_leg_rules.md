Original definitions from https://gtfs.org/schedule/reference/#fare_leg_rulestxt

{% docs gtfs_fare_leg_rules__leg_group_id %}
Identifies a group of entries in fare_leg_rules.txt.

Used to describe fare transfer rules between fare_transfer_rules.from_leg_group_id and fare_transfer_rules.to_leg_group_id.

Multiple entries in fare_leg_rules.txt may belong to the same fare_leg_rules.leg_group_id.

The same entry in fare_leg_rules.txt (not including fare_leg_rules.leg_group_id) must not belong to multiple fare_leg_rules.leg_group_id.
{% enddocs %}

{% docs gtfs_fare_leg_rules__network_id %}
Identifies a route network that applies for the fare leg rule.

If there are no matching fare_leg_rules.network_id values to the network_id being filtered, empty fare_leg_rules.network_id will be matched by default.

An empty entry in fare_leg_rules.network_id corresponds to all networks defined in routes.txt excluding the ones listed under fare_leg_rules.network_id
{% enddocs %}

{% docs gtfs_fare_leg_rules__from_area_id %}
Identifies a departure area.

If there are no matching fare_leg_rules.from_area_id values to the area_id being filtered, empty fare_leg_rules.from_area_id will be matched by default.

An empty entry in fare_leg_rules.from_area_id corresponds to all areas defined in areas.area_id excluding the ones listed under fare_leg_rules.from_area_id
{% enddocs %}

{% docs gtfs_fare_leg_rules__to_area_id %}
Identifies an arrival area.

If there are no matching fare_leg_rules.to_area_id values to the area_id being filtered, empty fare_leg_rules.to_area_id will be matched by default.

An empty entry in fare_leg_rules.to_area_id corresponds to all areas defined in areas.area_id excluding the ones listed under fare_leg_rules.to_area_id
{% enddocs %}

{% docs gtfs_fare_leg_rules__fare_product_id %}
The fare product required to travel the leg.
{% enddocs %}
