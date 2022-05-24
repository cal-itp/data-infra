
{% docs gtfs_fare_attributes__fare_id %}
Identifies a fare class.
{% enddocs %}

{% docs gtfs_fare_attributes__price %}
Fare price, in the unit specified by currency_type.
{% enddocs %}

{% docs gtfs_fare_attributes__currency_type %}
Currency used to pay the fare.
{% enddocs %}

{% docs gtfs_fare_attributes__payment_method %}
Indicates when the fare must be paid. Valid options are:

0 - Fare is paid on board.
1 - Fare must be paid before boarding.
{% enddocs %}

{% docs gtfs_fare_attributes__transfers %}
Indicates the number of transfers permitted on this fare. The fact that this field can be left empty is an exception to the requirement that a Required field must not be empty. Valid options are:

0 - No transfers permitted on this fare.
1 - Riders may transfer once.
2 - Riders may transfer twice.
empty - Unlimited transfers are permitted.
{% enddocs %}

{% docs gtfs_fare_attributes__agency_id %}
Identifies the relevant agency for a fare. This field is required for datasets with multiple agencies defined in agency.txt, otherwise it is optional.
{% enddocs %}

{% docs gtfs_fare_attributes__transfer_duration %}
Length of time in seconds before a transfer expires. When transfers=0 this field can be used to indicate how long a ticket is valid for or it can can be left empty.
{% enddocs %}
