{% docs customer_funding_source_customer_id %}

Unique identifier representing the customer that belongs to this customer funding source.

{% enddocs %}

{% docs customer_funding_source_principal_customer_id %}

The customer ID that the system initially creates when a new credit card has been identified.
Interactions between customer_id and principal_customer_id can be somewhat complicated, producing
rows whose customer_id is the principal for another row, but itself has a different principal. Some
additional context is available
[here](https://github.com/cal-itp/data-infra/pull/3070#issue-1975056371).

{% enddocs %}

{% docs int_payments__regional_agencies_first_tap_by_aggregation %}

One row per `aggregation_id` mapping it to the agency (organization) that operated the earliest
tap in that aggregation, for regional agencies only -- participants that appear in
`dim_payment_device_mapping`, where a single Littlepay `participant_id` can map to more than one
organization. Built off `fct_payments_rides_v2`, which already resolves the device-level
`organization_source_record_id` per ride alongside `aggregation_id` and `transaction_date_time_utc`. 

Intended to feed `first_tap_organization_source_record_id` into `fct_payments_aggregations`.

{% enddocs %}

{% docs payments_organization_source_record_id %}

`source_record_id` of the Cal-ITP defined organization (from `dim_organizations`) associated with this payments activity.
The mapping of organization records to payments entities is manually maintained in seed files: `payments_entity_mapping`
(participant-level).

{% enddocs %}
