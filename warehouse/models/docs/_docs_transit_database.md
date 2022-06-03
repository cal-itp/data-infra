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

{% docs organizations_table %}

Records are legal organizations, including companies, governmental bodies, or non-profits.

Table includes information on organizational properties (i.e. locale, type) as well as summarizations of its various relationships (e.g. `services` for a transit provider, or `products` for a vendor)

{% enddocs%}

{% docs services_table %}

Each record defines a transit service and its properties.

While there are a small number of exceptions (e.g. Solano Express, which is jointly managed by Solano and Napa), generally each transit service is managed by a single organization.

{% enddocs%}

{% docs products_table %}

Each record is a product used in a transit technology stack at another organization (e.g. fixed-route scheduling software) or by riders (e.g. Google Maps).  Products have properties such as input/output capabilities.

{% enddocs%}
