Original definitions from https://gtfs.org/schedule/reference/#fare_transfer_rulestxt

{% docs gtfs_fare_transfer_rules__from_leg_group_id %}
Identifies a group of pre-transfer fare leg rules.

If there are no matching fare_transfer_rules.from_leg_group_id values to the leg_group_id being filtered, empty fare_transfer_rules.from_leg_group_id will be matched by default.

An empty entry in fare_transfer_rules.from_leg_group_id corresponds to all leg groups defined under fare_leg_rules.leg_group_id excluding the ones listed under fare_transfer_rules.from_leg_group_id
{% enddocs %}

{% docs gtfs_fare_transfer_rules__to_leg_group_id %}
Identifies a group of post-transfer fare leg rules.

If there are no matching fare_transfer_rules.to_leg_group_id values to the leg_group_id being filtered, empty fare_transfer_rules.to_leg_group_id will be matched by default.

An empty entry in fare_transfer_rules.to_leg_group_id corresponds to all leg groups defined under fare_leg_rules.leg_group_id excluding the ones listed under fare_transfer_rules.to_leg_group_id
{% enddocs %}

{% docs gtfs_fare_transfer_rules__transfer_count %}
Defines how many consecutive transfers the transfer rule may be applied to.

Valid options are:
-1 - No limit.
1 or more - Defines how many transfers the transfer rule may span.

If a sub-journey matches multiple records with different transfer_counts, then the rule with the minimum transfer_count that is greater than or equal to the current transfer count of the sub-journey is to be selected.

Conditionally Forbidden:
- Forbidden if fare_transfer_rules.from_leg_group_id does not equal fare_transfer_rules.to_leg_group_id.
- Required if fare_transfer_rules.from_leg_group_id equals fare_transfer_rules.to_leg_group_id.
{% enddocs %}

{% docs gtfs_fare_transfer_rules__duration_limit %}
Defines the duration limit of the transfer.

Must be expressed in integer increments of seconds.

If there is no duration limit, fare_transfer_rules.duration_limit must be empty.
{% enddocs %}

{% docs gtfs_fare_transfer_rules__duration_limit_type %}
Defines the relative start and end of fare_transfer_rules.duration_limit.

Valid options are:
0 - Between the departure fare validation of the current leg and the arrival fare validation of the next leg.
1 - Between the departure fare validation of the current leg and the departure fare validation of the next leg.
2 - Between the arrival fare validation of the current leg and the departure fare validation of the next leg.
3 - Between the arrival fare validation of the current leg and the arrival fare validation of the next leg.

Conditionally Required:
- Required if fare_transfer_rules.duration_limit is defined.
- Forbidden if fare_transfer_rules.duration_limit is empty.
{% enddocs %}

{% docs gtfs_fare_transfer_rules__fare_transfer_type %}
Valid options are:
0 - From-leg fare_leg_rules.fare_product_id plus fare_transfer_rules.fare_product_id; A + AB.
1 - From-leg fare_leg_rules.fare_product_id plus fare_transfer_rules.fare_product_id plus to-leg fare_leg_rules.fare_product_id; A + AB + B.
2 - fare_transfer_rules.fare_product_id; AB.

More details including visual explanations available at https://gtfs.org/schedule/reference/#fare_transfer_rulestxt
{% enddocs %}

{% docs gtfs_fare_transfer_rules__fare_product_id %}
The fare product required to transfer between two fare legs. If empty, the cost of the transfer rule is 0.
{% enddocs %}
