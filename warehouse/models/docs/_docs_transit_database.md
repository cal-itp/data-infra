Docs for the Transit Database models; usually these are copied directly from Airtable.

{% docs components_table %}

Each component represents a single piece in a
transit technology stack.  It is part of a single
`Component Group` (e.g. CAD/AVL) which are often
bundled together, which in turn is part of a
`Function Group` (e.g. Fare collection, scheduling,
etc) and is operated in physical space defined
in `Location` (e.g. Cloud, Vehicle, etc.)

This is currently a current-only table, so historical data is not present and the data represents
the record states as they existed in the most recent extract from the source database.
Versioning columns (`_valid_from` and `_valid_to` for validity dates and `source_record_id` for a stable identifier)
are implemented for future schema consistency, but historical data has not yet been incorporated.

{% enddocs%}

{% docs contracts_table %}

Each record is a contract between `organizations` to either provide one or more `products` or operate one or more `services`.  Each contract has properties such as execution date, expiration, and renewals.

This is currently a current-only table, so historical data is not present and the data represents
the record states as they existed in the most recent extract from the source database.
Versioning columns (`_valid_from` and `_valid_to` for validity dates and `source_record_id` for a stable identifier)
are implemented for future schema consistency, but historical data has not yet been incorporated.

{% enddocs%}

{% docs data_schemas_table %}

Each record indicates a data schema which  can be used in one or more `relationships service-components`.

This is currently a current-only table, so historical data is not present and the data represents
the record states as they existed in the most recent extract from the source database.
Versioning columns (`_valid_from` and `_valid_to` for validity dates and `source_record_id` for a stable identifier)
are implemented for future schema consistency, but historical data has not yet been incorporated.

{% enddocs%}

{% docs organizations_table %}

Records are legal organizations, including companies, governmental bodies, or non-profits.

Table includes information on organizational properties (i.e. locale, type) as well as summarizations of its various relationships (e.g. `services` for a transit provider, or `products` for a vendor)

For more information, see [the Airtable Data Documentation document](https://docs.google.com/document/d/1KvlYRYB8cnyTOkT1Q0BbBmdQNguK_AMzhSV5ELXiZR4/).

Each row in this table is a record version, where the record
had the given set of attributes. When an attribute changes, a new
version is created.
`source_record_id` is the record identifier from Airtable
and is a stable identifier for a given record over time.
`_valid_from` and `_valid_to` columns represent the
time period during which this record version
was in effect.

{% enddocs%}

{% docs services_table %}

Each record defines a transit service and its properties.

While there are a small number of exceptions (e.g. Solano Express, which is jointly managed by Solano and Napa), generally each transit service is managed by a single organization.

For more information, see [the Airtable Data Documentation document](https://docs.google.com/document/d/1KvlYRYB8cnyTOkT1Q0BbBmdQNguK_AMzhSV5ELXiZR4/).

Each row in this table is a record version, where the record
had the given set of attributes. When an attribute changes, a new
version is created.
`source_record_id` is the record identifier from Airtable
and is a stable identifier for a given record over time.
`_valid_from` and `_valid_to` columns represent the
time period during which this record version
was in effect.

{% enddocs%}

{% docs products_table %}

Each record is a product used in a transit technology stack at another organization (e.g. fixed-route scheduling software) or by riders (e.g. Google Maps).  Products have properties such as input/output capabilities.



This is currently a current-only table, so historical data is not present and the data represents
the record states as they existed in the most recent extract from the source database.
Versioning columns (`_valid_from` and `_valid_to` for validity dates and `source_record_id` for a stable identifier)
are implemented for future schema consistency, but historical data has not yet been incorporated.

{% enddocs%}

{% docs service_components_table %}

Each record is an association between one or more `services`, a `product`, and one or more `components` which that product is serving as.

Each row in this table is a relationship version, where the record
had the given set of attributes. Because `dim_services` and `dim_organizations` are fully versioned but `dim_products` and `dim_components` are not,
this represents the relationship between historical service and organization (vendor) records and current product and component records.
When products and components are made fully historical, the relationships will be fully historical as well.

When an attribute changes, a new
version is created.
`source_record_id` is the record identifier from Airtable
and is a stable identifier for a given record over time.
`_valid_from` and `_valid_to` columns represent the
time period during which this record version
was in effect.

{% enddocs%}

{% docs gtfs_datasets_table %}

Each record represents a gtfs dataset (feed) that is either a type of GTFS Schedule, Trip Updates, Vehicle Locations or Alerts.

A gtfs dataset MAY:
- be *disaggregated into* one or more `gtfs service data` records.
- be *produced* by one or more `organizations`
- be *published* by an `organizations`.

For more information, see [the Airtable Data Documentation document](https://docs.google.com/document/d/1KvlYRYB8cnyTOkT1Q0BbBmdQNguK_AMzhSV5ELXiZR4/).

Each row in this table is a record version, where the record
had the given set of attributes. When an attribute changes, a new
version is created.
`source_record_id` is the record identifier from Airtable
and is a stable identifier for a given record over time.
`_valid_from` and `_valid_to` columns represent the
time period during which this record version
was in effect.

{% enddocs%}

{% docs gtfs_service_data_table %}

Each record links together a single `gtfs dataset` and one (if possible) or more `services`.  Additional fields define how to isolate the service within the `gtfs dataset`.

Many services have more than one GTFS dataset which describes their service. Often these are either precursors to *final* datasets (e.g. AC Transit's GTFS dataset is a precursor to the Bay Area 511 dataset) or artifacts produced in other processes such as creating GTFS Realtime.

For more information, see [the Airtable Data Documentation document](https://docs.google.com/document/d/1KvlYRYB8cnyTOkT1Q0BbBmdQNguK_AMzhSV5ELXiZR4/).

Each row in this table is a record version, where the record
had the given set of attributes. When an attribute changes, a new
version is created.
`source_record_id` is the record identifier from Airtable
and is a stable identifier for a given record over time.
`_valid_from` and `_valid_to` columns represent the
time period during which this record version
was in effect.

{% enddocs%}

{% docs county_geography_table %}

Data representing county geography. Further description needed.

This is currently a current-only table, so historical data is not present and the data represents
the record states as they existed in the most recent extract from the source database.
Versioning columns (`_valid_from` and `_valid_to` for validity dates and `source_record_id` for a stable identifier)
are implemented for future schema consistency, but historical data has not yet been incorporated.

{% enddocs%}

{% docs eligibility_programs_table %}

Data representing eligibility programs. Further description needed.

This is currently a current-only table, so historical data is not present and the data represents
the record states as they existed in the most recent extract from the source database.
Versioning columns (`_valid_from` and `_valid_to` for validity dates and `source_record_id` for a stable identifier)
are implemented for future schema consistency, but historical data has not yet been incorporated.

{% enddocs%}

{% docs fare_systems_table %}

Data representing fare systems. Further description needed.

WIP

An import from o.g. Trillium research circa 2020 stored in [this document](https://docs.google.com/spreadsheets/d/1qr49azk6p30mp96_7myKoO-Bb_bXMMn5ZzgbL-uPiPw/edit?usp=drive_web&ouid=116512595786393675275)

This is currently a current-only table, so historical data is not present and the data represents
the record states as they existed in the most recent extract from the source database.
Versioning columns (`_valid_from` and `_valid_to` for validity dates and `source_record_id` for a stable identifier)
are implemented for future schema consistency, but historical data has not yet been incorporated.

{% enddocs%}

{% docs funding_programs_table %}

Data representing funding programs. Further description needed.

This is currently a current-only table, so historical data is not present and the data represents
the record states as they existed in the most recent extract from the source database.
Versioning columns (`_valid_from` and `_valid_to` for validity dates and `source_record_id` for a stable identifier)
are implemented for future schema consistency, but historical data has not yet been incorporated.

{% enddocs%}

{% docs ntd_agency_info_table %}

DEPRECATED: Please use mart_ntd.dim_annual_agency_information going forward.

2018 NTD Agency Info Table
Imported 10/6/2021 from fta.gov

This is currently a current-only table, so historical data is not present and the data represents
the record states as they existed in the most recent extract from the source database.
Versioning columns (`_valid_from` and `_valid_to` for validity dates and `source_record_id` for a stable identifier)
are implemented for future schema consistency, but historical data has not yet been incorporated.

{% enddocs%}
