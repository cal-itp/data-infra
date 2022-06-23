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

{% docs service_components_table %}

Each record is an association between one or more `services`, a `product`, and one or more `components` which that product is serving as.

{% enddocs%}

{% docs gtfs_datasets_table %}

Each record represents a gtfs dataset (feed) that is either a type of GTFS Schedule, Trip Updates, Vehicle Locations or Alerts.

A gtfs dataset MAY:
- be *disaggregated into* one or more `gtfs service data` records.
- be *produced* by one or more `organizations`
- be *published* by an `organizations`.

{% enddocs%}

{% docs gtfs_service_data_table %}

Each record links together a single `gtfs dataset` and one (if possible) or more `services`.  Additional fields define how to isolate the service within the `gtfs dataset`.

Many services have more than one GTFS dataset which describes their service. Often these are either precursors to *final* datasets (e.g. AC Transit's GTFS dataset is a precursor to the Bay Area 511 dataset) or artifacts produced in other processes such as creating GTFS Realtime.

{% enddocs%}

{% docs county_geography_table %}

Data representing county geography. Further description needed.

{% enddocs%}

{% docs eligibility_programs_table %}

Data representing eligibility programs. Further description needed.

{% enddocs%}

{% docs fare_systems_table %}

Data representing fare systems. Further description needed.

{% enddocs%}

{% docs funding_programs_table %}

Data representing funding programs. Further description needed.

{% enddocs%}

{% docs ntd_agency_info_table %}

2018 NTD Agency Info Table
Imported 10/6/2021 from fta.gov

{% enddocs%}

{% docs place_geography_table %}

Geographic info from: [https://www.census.gov/library/reference/code-lists/ansi.html](https://www.census.gov/library/reference/code-lists/ansi.html)

{% enddocs%}

{% docs rider_requirements_table %}

Data representing rider requirements. Further description needed.

{% enddocs%}
