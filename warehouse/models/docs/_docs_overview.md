{% docs __overview__ %}
# Cal-ITP Data Warehouse

The Cal-ITP Data Warehouse contains four core types of data (a few other data sources are available, but the primary data models are composed of the following):

* **GTFS pipeline data, generally in `mart_gtfs`**: This is [GTFS data](https://gtfs.org/) (both schedule and realtime) scraped by the Cal-ITP pipeline. The raw data here is produced by transit agencies and is of variable quality and completeness. To understand the GTFS data format and terms (for example, "trips", "stops", "routes"), the GTFS specification documentation at [gtfs.org](https://gtfs.org/) may be helpful.

* **GTFS quality data, generally in `mart_gtfs_quality`**: This is data about the *quality* of the raw GTFS data described above: how well it conforms to the GTFS specification (which is assessed based on the outputs of the canonical GTFS validators for [schedule](https://github.com/MobilityData/gtfs-validator) and [realtime](https://github.com/MobilityData/gtfs-realtime-validator)) and how well it adheres to the [California Transit Data Guidelines](https://dot.ca.gov/cal-itp/california-transit-data-guidelines).

* **Transit Database data, generally in `mart_transit_database`**: This is data hand-collected by Cal-ITP about transit in California, including things like organizations (whether they are transit providers, vendors, or other participants in the transit ecosystem); transit services; GTFS datasets; contracts; components of a transit technology stack; etc. For additional documentation of the Transit Database data model, see the [Airtable Data Documentation](https://docs.google.com/document/d/1KvlYRYB8cnyTOkT1Q0BbBmdQNguK_AMzhSV5ELXiZR4/edit#heading=h.u7y2eosf0i1d) or the older [Transit Database docs](https://docs.calitp.org/data-infra/datasets_and_tables/transitdatabase.html).

* **Payments data, generally in `mart_payments`**: Data provided by fare processors (such as Littlepay) that includes device transactions, payments, funding sources, etc. Currently this data is sourced from vendor-provided published artifacts (such as S3 files) and used to power agency-facing dashboards showing usage of contactless payments. Mart models for this data must have row-level access controls to ensure agencies only see their data.

## Naming and types of models

Data models (tables and views) are usually of one of the following types:

* **Dimensions:** These tables are prefixed with `dim_` and are ["typically likened to nouns"](https://docs.getdbt.com/terms/dimensional-modeling#dimensions), i.e., the entity associated with an event. Many of our dimension tables are [type-2 slowly changing dimensions](https://en.wikipedia.org/wiki/Slowly_changing_dimension#Type_2:_add_new_row) and have `_valid_from` and `_valid_to` columns that indicate the period of time that that version of a record was in effect.

* **Facts:** These tables are prefixed with `fct_` and ["typically refer to an action, event, or result of a business process"](https://docs.getdbt.com/terms/dimensional-modeling#facts), i.e., a thing that happened (or was scheduled to happen) at a specific time or at a specific temporal granularity.

* **Bridges:** Bridge tables are prefixed with `bridge_` and represent a mapping between two dimension tables where 1. The relationship itself is many to many and/or 2. Because both dimensions are versioned (slowly-changing), the relationship becomes many to many because of overlapping record versions. In case #2, bridge tables must be joined with reference to a specific date (so, you must select the relationship between Organization A and Service B *as of January 1, 2023*, because if you just look for the relationship between Organization A and Service B, you will get multiple rows representing the different iterations of that relationship over time.) These versioned bridge tables will have `_valid_from` and `_valid_to` dates like a dimension table.

## Keys and versioning

Columns called `key` are unique, synthetic (i.e., semantically meaningless hashes), non-null primary keys for the given table. (For GTFS data, we maintain a column called `_gtfs_key` that is a similarly-constructed key, but uses the GTFS-defined primary key construction rather than a known primary key i.e. line number in a source CSV). For versioned dimension tables, the `key` column will be a **versioned** primary key, and there may be an unversioned natural key from the source system also present on the table. Foreign keys will be prefixed with the entity name of the other table. `key` columns should generally only be used for joins or getting distinct counts of entities.

"Versioning" refers to the idea that the same entity is present in our data but changes over time. So, for example, `Organization A` may change its website from `organizationa.net` to `organizationatransit.com` on January 15, 2023. We will have one version of the Organization A record up to January 15 and a new version after. In this case, the unversioned key (for `dim_organizations`, this is `source_record_id`) will be the same before and after January 15, but the versioned key (`key`) will change, and the two record versions will have different `_valid_from` and `_valid_to` dates, with a break on January 15.

### Examples: Key column naming

The primary key for `mart_transit_database.dim_gtfs_datasets` is called `key`. The unversioned natural key is `source_record_id`, which is specific to and generated by the Transit Database source system. Then in the `mart_gtfs.fct_scheduled_trips` table, the foreign key referencing `mart_transit_database.dim_gtfs_datasets.key` is called `gtfs_dataset_key`.

Similarly, the primary key for `mart_gtfs.dim_trips` is called `key`. The unversioned natural key is `trip_id`, which is assigned in the original GTFS feed (this means `trip_id` is only unique within a given feed, so within our warehouse you would only expect the `trip_id + feed_key` combination to be unique). Because some GTFS feeds erroneously contain duplicate `trip_id` values, there is an additional column called `warning_duplicate_gtfs_key`, which flags cases where `trip_id + feed_key`, and thus the synthetic `key` column, are not unique.  Then in the `mart_gtfs.fct_scheduled_trips` table, the foreign key referencing `mart_gtfs.dim_trips.key` is called `trip_key` and the `warning_duplicate_gtfs_key` column is also provided to flag the duplicates.

| Entity                                                                                   | Unversioned natural key           | Versioned key                                                                                                    |
|------------------------------------------------------------------------------------------|-----------------------------------|------------------------------------------------------------------------------------------------------------------|
| Downloaded GTFS feed                                                                     | `base64_url`                      | `mart_gtfs.dim_schedule_feeds.key` or (when foreign key) `feed_key`, constructed from `base64_url + _valid_from` |
| Individual line within a downloaded GTFS feed (i.e. a literal row in a source CSV)       | `base64_url + _line_number`       | `mart_gtfs.dim_*.key`, constructed from `mart_gtfs.dim_*._line_number + feed_key`                                |
| Individual record within a downloaded GTFS feed (ex. an individual route, trip, or stop) | `base64_url + <GTFS-defined key>` | `mart_gtfs.dim_*._gtfs_key`, constructed from `mart_gtfs.dim_*.<GTFS-defined key> + feed_key`                    |
| Airtable records (ex. organizations, services, or GTFS datasets)                         | `source_record_id`                | `mart_transit_database.dim_*.key`, constructed from `source_record_id + _valid_from`                             |

## Key questions

When starting a new analysis, some questions to consider include:

* **What grain (granularity) am I targeting? What should one row in my final output represent?** For example, do I want one row per organization per day? Or one row per trip on one specific date? From this, you can figure out what entity versioning will be relevant. If working with data as of one date, you can identify the record versions that were in effect on that date. If working with data over time, you will need to consider what stable (unversioned / natural) key you can use to track an entity as it changes over your time period of interest.

* **When joining: What is the cardinality of this relationship?** When performing joins, you should consider whether the join will change the cardinality (number of rows) of the table of interest. Is the relationship one to one, one to many, or many to many? If the relationship is one to one but you are dealing with slowly changing data, you should consider how to handle the relationship versioning (for example, in a bridge table) in addition to the individual record versioning.

{% enddocs %}
