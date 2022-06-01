Docs for the Transit Database models; usually these are copied directly from Airtable.

{% docs components_table %}

Each component represents a single piece in a
transit technology stack.  It is part of a single
`Component Group` (e.g. CAD/AVL) which are often
bundled together, which in turn is part of a
`Function Group` (e.g. Fare collection, scheduling,
etc) and is operated in physical space defined
in `Location` (e.g. Cloud, Vehicle, etc.)

{% enddocs%}

{% docs contracts_table %}

Each record is a contract between `organizations` to either provide one or more `products` or operate one or more `services`.  Each contract has properties such as execution date, expiration, and renewals.

{% enddocs%}

{% docs data_schemas_table %}

Each record indicates a data schema which  can be used in one or more `relationships service-components`.

{% enddocs%}
