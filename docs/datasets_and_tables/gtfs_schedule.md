# GTFS Schedule

## Data

| dataset | description |
| ------- | ----------- |
| [(Reference) GTFS-Schedule Data Standard](https://developers.google.com/transit/gtfs/reference#agencytxt) | A reference to the GTFS-Schedule data standard. |
| [gtfs_schedule](gtfs-schedule) | Latest warehouse data for GTFS-Schedule feeds. See the [GTFS-Schedule reference](https://developers.google.com/transit/gtfs/reference). |
| [gtfs_schedule_type2](gtfs-schedule-type2) | Tables with GTFS-Static feeds across history (going back to April 15th, 2021). These are stored as type 2 slowly changing dimensions. They have `calitp_extracted_at`, and `calitp_deleted_at` fields. |
| [(Internal) gtfs_schedule_history](gtfs-schedule-history) | External tables with all new feed data across history. |

### (Reference) GTFS-Schedule Data Standard - Tables
For background on the tables used in the GTFS-Schedule standard, see the [GTFS-Schedule data standard](https://developers.google.com/transit/gtfs/reference#agencytxt).

(gtfs-schedule)=
### gtfs_schedule
Latest warehouse data for GTFS Static feeds. See the [GTFS-Schedule reference](https://developers.google.com/transit/gtfs/reference).

|table             |link                                                                                             |
|------------------|-------------------------------------------------------------------------------------------------|
|agency            |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.agency">link</a>            |
|attributions      |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.attributions">link</a>      |
|calendar          |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.calendar">link</a>          |
|calendar_dates    |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.calendar_dates">link</a>    |
|fare_attributes   |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.fare_attributes">link</a>   |
|fare_rules        |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.fare_rules#details">link</a>|
|feed_info         |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.feed_info">link</a>         |
|frequencies       |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.frequencies">link</a>       |
|levels            |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.levels">link</a>            |
|pathways          |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.pathways">link</a>          |
|routes            |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.routes">link</a>            |
|shapes            |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.shapes">link</a>            |
|stop_times        |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.stop_times">link</a>        |
|stops             |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.stops">link</a>             |
|transfers         |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.transfers">link</a>         |
|translations      |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.translations">link</a>      |
|trips             |<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.trips">link</a>             |
|validation_notices|<a href="https://dbt-docs.calitp.org/#!/model/model.calitp_warehouse.validation_notices">link</a>|

(gtfs-schedule-type2)=
### gtfs_schedule_type2
Tables with GTFS Static feeds across history (going back to April 15th, 2021). These are stored as type 2 slowly changing dimensions. They have `calitp_extracted_at`, and `calitp_deleted_at` fields.

|dataset   |table             |link                                                                                                          |
|----------|------------------|--------------------------------------------------------------------------------------------------------------|
|gtfs_type2|agency            |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_type2.agency">link</a>            |
|gtfs_type2|attributions      |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_type2.attributions">link</a>      |
|gtfs_type2|calendar          |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_type2.calendar">link</a>          |
|gtfs_type2|calendar_dates    |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_type2.calendar_dates">link</a>    |
|gtfs_type2|fare_attributes   |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_type2.fare_attributes">link</a>   |
|gtfs_type2|fare_rules        |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_type2.fare_rules">link</a>        |
|gtfs_type2|feed_info         |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_type2.feed_info">link</a>         |
|gtfs_type2|frequencies       |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_type2.frequencies">link</a>       |
|gtfs_type2|levels            |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_type2.levels">link</a>            |
|gtfs_type2|pathways          |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_type2.pathways">link</a>          |
|gtfs_type2|routes            |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_type2.routes">link</a>            |
|gtfs_type2|shapes            |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_type2.shapes">link</a>            |
|gtfs_type2|stop_times        |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_type2.stop_times">link</a>        |
|gtfs_type2|stops             |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_type2.stops">link</a>             |
|gtfs_type2|transfers         |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_type2.transfers">link</a>         |
|gtfs_type2|translations      |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_type2.translations">link</a>      |
|gtfs_type2|trips             |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_type2.trips">link</a>             |
|gtfs_type2|validation_notices|<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_type2.validation_notices">link</a>|

(gtfs-schedule-history)=
### (Internal) gtfs_schedule_history
External tables with all new feed data across history.

|dataset              |table                          |link                                                                                                                                  |
|---------------------|-------------------------------|--------------------------------------------------------------------------------------------------------------------------------------|
|gtfs_schedule_history|calitp_feed_parse_result       |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_schedule_history.calitp_feed_parse_result">link</a>       |
|gtfs_schedule_history|calitp_feed_tables_parse_result|<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_schedule_history.calitp_feed_tables_parse_result">link</a>|
|gtfs_schedule_history|calitp_feed_updates            |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_schedule_history.calitp_feed_updates">link</a>            |
|gtfs_schedule_history|calitp_feeds                   |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_schedule_history.calitp_feeds">link</a>                   |
|gtfs_schedule_history|calitp_feeds_raw               |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_schedule_history.calitp_feeds_raw">link</a>               |
|gtfs_schedule_history|calitp_files_updates           |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_schedule_history.calitp_files_updates">link</a>           |
|gtfs_schedule_history|calitp_included_gtfs_tables    |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_schedule_history.calitp_included_gtfs_tables">link</a>    |
|gtfs_schedule_history|calitp_status                  |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_schedule_history.calitp_status">link</a>                  |
|gtfs_schedule_history|validation_code_descriptions   |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_schedule_history.validation_code_descriptions">link</a>   |
|gtfs_schedule_history|validation_notice_fields       |<a href="https://dbt-docs.calitp.org/#!/source/source.calitp_warehouse.gtfs_schedule_history.validation_notice_fields">link</a>       |
