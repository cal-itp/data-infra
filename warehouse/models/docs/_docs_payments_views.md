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
