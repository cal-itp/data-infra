# Transit Database

The Cal-ITP Airtable Transit Database stores key relationships about how transit services are organized and operated in California as well as how well they are performing. See Evan or Hunter to get a link and gain access.

We have chosen to group and maintain the tables into the following Airbases as follows:

| **Table Set** | **Description** | **Data Maintainer** |
| :------------ | :-------------- | :------------------ |
| [**California Transit**](#california-transit) | Defines key organizational relationships and properties. Organizations, geography, funding programs,  transit services, service characteristics, transit datasets such as GTFS, and the intersection between transit datasets and services. | *Elizabeth*<br>Evan handling uptake to warehouse |
| [**Transit Data Assessments**](#transit-data-assessments) | Articulates data performance metrics and assessments.| *Elizabeth*<br>*Evan* handling uptake to warehouse<br>*Olivia* a key User Advocate. |
| [**Transit Technology Stacks**](#transit-technology-stacks) | Defines operational setups at transit provider organizations. Defines relationships between vendor organizations, transit provider and operator organizations, products, contracts to provide products, transit stack components, and how they relate to one-another. Structure still somewhat a `WIP`. | *Elizabeth*<br>No warehouse uptake for time being. |

While `organizations` and `services` are central to many of the tables, we have chosen to maintain them as part of the Transit Services base which will be referenced by the other two.

## Airtable things

### Primary Keys

Airtable forces the use of the left-most field as the primary key of the database: the field that must be referenced in other tables, similar to a VLOOKUP in a spreadsheet. Unlike many databases, Airtable doesn't enforce uniqueness in the values of the primary key field.  Instead, it assigns it an underlying and mostly hidden unique [`RECORD ID`](https://support.airtable.com/hc/en-us/articles/360051564873-Record-ID), which can be exposed by creating a formula field to reference it.

For the sake of this documentation, we've noted the [`Primary Field`](https://support.airtable.com/hc/en-us/articles/202624179-The-primary-field), which is not guaranteed to be unique. Some tables additionally expose the unique [`RECORD ID`](https://support.airtable.com/hc/en-us/articles/360051564873-Record-ID) as well.

### Full Documentation of Fields

AirTable does not currently have an effective mechanism to programmaticaly download your data schema (they have currently paused issuing keys to their metadata API). Rather than manually type-out and export each individual field definition from AirTable, please see the [AirTable-based documentation of fields](https://airtable.com/appPnJWrQ7ui4UmIl/api/docs) which is produced as a part of their API documentation. Note that you must be authenticated with access to the base to reach this link.

## Related Data

The data in the Airtable Transit Database is distinct but related to the following data:

- [GTFS Schedule Quality Assessment Airflow pipelines](/airflow/static-schedule-pipeline) results in the [warehouse](/warehouse/overview)
- [GTFS Schedules Datasets](gtfs_schedule)

Currently neither of the above processes or datasets either rely on or contribute back to the Airflow Transit Database – this is a work in progress.  Rather, they rely on the list of transit datasets in the file [`agencies.yml`](https://github.com/cal-itp/data-infra/tree/main/airflow/data/agencies.yml) to dictate what datasets to download and assess.

## California Transit

| **Name**<br>*Key(s)*| **Description** |
| :------------- |  :-------------- |
| `organizations`<br><br>*Primary Field*: `Name` | Records are legal organizations, including companies, governmental bodies, or non-profits. <br><br>Table includes information on organizational properties (i.e. locale, type) as well as summarizations of its various relationships (e.g. `services` for a transit provider, or `products` for a vendor). <br> <br>An organization MAY:<br><ul><li>*manage* one more more `services`</li><li>*operate* one more `services`</li><li>*own* one more `contracts`</li><li>*hold* one more `contracts`</li><li>*sell* one more `products`</li><li>*consume* one more `gtfs datasets`</li><li>*produce* one more `gtfs datasets`</li></ul>
| `services`<br><br>*Primary Field*: `Name` | Each record defines a transit service and its properties.<br><br>While there are a small number of exceptions (e.g. Solano Express, which is jointly managed by Solano and Napa), generally each transit service is managed by a single organization. Transit services are differentiated from each other by variation (or the potentiality of variation) in one or more of the following:<ul><li>operator `organization` such as City Staff vs a contracted service,<li>`rider requirements` such as ADA Paratransit eligibility, senior status, school trips, etc.</li><li>Operational characteristics such as reservations, on-demand vs fixed-route, service frequencies, and mode</li>Business processes such as transit technology stacks or personnel</li><li>Funding type, which can effect longevity of the service and how well integrated it is with other services managed by the same organization.</li><li>Rider-facing branding, which is often an indicator of one of the above.</li></ul><br>Services MAY:<ul><li>be *reflected by* a `gtfs service data` record</li><li>be *subject to* one or more `rider requirements`</li><li>be *funded by* one or more `funding programs`</li><li>*operated by* one or more `organizations`</li><li>*managed by* one or more organizations</li><li>be *operated in* one or more `place geography`</li><li>*use* one or more `products`. |
| `tasks`<br><br> *Primary Field*: `Name` | Each record defines an action we are either undertaking or tracking to meet our OKRs and quarterly milestones.  These tasks are helpful for crosswalking "what we are doing" with each GTFS-entity. |
| `gtfs datasets`<br><br>*Primary Field*: `gtfs_dataset_id` | Each record represents a gtfs dataset (feed) that is either a type of GTFS Schedule, Trip Updates, Vehicle Locations or Alerts.  A gtfs dataset MAY:<ul><li>be *disaggregated into* one or more `gtfs service data` records.</li><li>be *produced* by one or more `organizations`</li><li>be *published* by an `organizations`. |
| `gtfs service data` <br><br> *Primary Field*: `Name`, a combination of a set of `Services` record(s) and a single `gtfs datasets` record. | Each record links together a single `gtfs dataset` and one (if possible) or more `services`.  Additional fields define how to isolate the service within the `gtfs dataset`.  <br><br>Many services have more than one GTFS dataset which describes their service. Often these are either precursors to *final* datasets (e.g. AC Transit's GTFS dataset is a precursor to the Bay Area 511 dataset) or artifacts produced in other processes such as creating GTFS Realtime (e.g. [the VCTC GTFS produced by GMV](https://airtable.com/appPnJWrQ7ui4UmIl/tblnVt5FZ2FZmDjDx/viw3NtcDP3Qm0BYyG/recJhrNj21mYVETJG?blocks=hide)). The property `Category` indicates if this is the `primary` dataset, a `precursor` or `unknown` in order to distinguish which should be used. See |
| `place geography` <br><br> *Primary Field*: `Name` | Each place is a Census recognized Place with a FIPS code.  Additional properties include County and Caltrans District. |
| `county geography` <br><br> *Primary Field*: `Name` | Each record is a county and has fields to lookup key information about that county such as Caltrans District. |
| `fare systems`  <br><br> *Primary Field*: `Fare System` | `WIP` A list of fare systems and their properties. Fare systems apply to one or more Organization which manages a service. |
| `funding programs` <br><br>*Primary Field*: `Program` | `WIP` A very broad list of funding programs for `services` such that we are able to identify which `services` may be subject to various requirements and/or to better classify `services`. |
| `rider requirements` <br><br> *Primary Field*: `Requirement` | A very broad list of rider requirements to categorize and analyze `services`. |
| `eligibility programs` <br><br> *Primary Field*: `Program` | `WIP` Each record is a program/process which riders must use to become eligible to ride one or more `services`.  Each program is operated by an `organization` and evaluates one or more `rider requirements`.  |
| `service-component` | Imported table from [Transit Technology Stacks](#transit-technology-stacks) which allows us to look at what products services use. |
| `feed metrics` | Metrics (i.e. service area, population, etc. ) that are calculated by Data Analysts using data warehouse that are useful for planning and strategy.  **Not necessarily up-to-date; should be used as back of the envelope numbers onl; not for presentation.** |
| `NTD Agency Info` | 2018 NTD Agency Info Table imported 10/6/2021 from https://www7.fta.dot.gov/ntd/data-product/2018-annual-database-agency-information |
| `API Keys` | Storage of API keys for accessing `gtfs datasets` via a keyed API |

### Additional Field Documentation

Because fields are documented in the Airtable GUI itself and its associated API documentation, this section only contains additional information that cannot be appropriately documented in those places or is specific to the needs of the Data Services team.

#### `gtfs service data` notation for isolating GTFS Services within GTFS Datasets

Context: `gtfs service data` is an association table between `services` and subsets (or entire) `GTFS Datasets`.

Summary:

- Selection levels are in following order `agency_id`, `network_id`, `route_id`
- `BLANK` indicates ALL records
- Comma-separated list for values that should be selected at that selection level
- `*` indicates remaining records after other selections at that selection level

Relevant Fields:

- `gtfs service data.agency_id`: if only a selection of `agency.agency_id` within the GTFS Dataset should be selected to represent a specific `services` record, list them here.  If all `agency_id` should be selected, leave blank.  Indicate if the "leftover" `agency_id` from other `agency_id` selections for the same `GTFS dataset` should be selected with `*`.
- `gtfs service data.network_id`: if only a selection of `routes.network_id` within the GTFS Dataset should be selected to represent a specific `services` record, list them here.  If all `network_id` within the `agency_id` selection should be selected, leave blank.  Indicate if the "leftover" `network_id` from other `network_id` selections for the same `GTFS dataset` should be selected with `*`.
- `gtfs service data.route_id`: if only a selection of `routes.route_id` within the GTFS Dataset should be selected to represent a specific `services` record, list them here.  If all `route_id` within the `agency_id` and `network_id` selection should be selected, leave blank.  Indicate if the "leftover" `route_id` from other `route_id` selections for the same `GTFS dataset` should be selected with `*`.

### California Transit: Entity Relationship Diagram

[![](https://mermaid.ink/img/pako:eNqVVEtv4jAQ_iuWz0W9c1stbbWHbhFw5DLEEzJax07HDqss4b_vOCQQXlLLBSX6XuP5nL3OvEE91cgzgi1DuXZKfh-8BUf_IJJ36tBOJn6vlsg7ynCq1roEB1sMa_0ltK-QIT6C-w7-FvMwgwgBY6Jk3oW6_BalYm_q7HuUemMpFEfOY9b4XaJRUBUwuqj8GO3zu9btQxEwJTkKEZnc9sta7a3W-_zjebGa_1C5ZxULVJIO0sN3RCRQolYWnEt5oI6FZ4rNQ9VHw7bqp69dbN7QS6OqounlCwTzWQPLwGgUuUHnCq3atgs4t5DhhYbBkDFtMKiso0ws7tCKkoQqjwFG8V4l77KR4y0HxeuRoaosiVr05wL0vQ3D8kc9Pu4dIoMLFAer3qx2Rk5tzilu2V2C9oKcC-DUzQUZ5AV-1sRYpiLdml1mS6QXS1uSwsbm5HLDsvLvgtCwA5Pt93czX3ck_Y3oX6WLkTQYc4tZlBVtmsF7dHGG2e4wKS2mrJiCkM8VXkH4c_c8Bep3GJ7_ehaAPxXiFdG8Y2TKwtCoq5t7bkIqJqOVne5QiaLnCE7mO9v_Xs1-SUMGpXEJQtIqvDXinueUEdgEV0acujz6SZco3SIj38h90ltrcSxxrY8xcqhtTE4HgdaVEPHFUPSsp5FrfNJyjfyycdnwfMT0H1s9zcEGPPwHJNjt_A)](https://mermaid-js.github.io/mermaid-live-editor/edit/#pako:eNqVVEtv4jAQ_iuWz0W9c1stbbWHbhFw5DLEEzJax07HDqss4b_vOCQQXlLLBSX6XuP5nL3OvEE91cgzgi1DuXZKfh-8BUf_IJJ36tBOJn6vlsg7ynCq1roEB1sMa_0ltK-QIT6C-w7-FvMwgwgBY6Jk3oW6_BalYm_q7HuUemMpFEfOY9b4XaJRUBUwuqj8GO3zu9btQxEwJTkKEZnc9sta7a3W-_zjebGa_1C5ZxULVJIO0sN3RCRQolYWnEt5oI6FZ4rNQ9VHw7bqp69dbN7QS6OqounlCwTzWQPLwGgUuUHnCq3atgs4t5DhhYbBkDFtMKiso0ws7tCKkoQqjwFG8V4l77KR4y0HxeuRoaosiVr05wL0vQ3D8kc9Pu4dIoMLFAer3qx2Rk5tzilu2V2C9oKcC-DUzQUZ5AV-1sRYpiLdml1mS6QXS1uSwsbm5HLDsvLvgtCwA5Pt93czX3ck_Y3oX6WLkTQYc4tZlBVtmsF7dHGG2e4wKS2mrJiCkM8VXkH4c_c8Bep3GJ7_ehaAPxXiFdG8Y2TKwtCoq5t7bkIqJqOVne5QiaLnCE7mO9v_Xs1-SUMGpXEJQtIqvDXinueUEdgEV0acujz6SZco3SIj38h90ltrcSxxrY8xcqhtTE4HgdaVEPHFUPSsp5FrfNJyjfyycdnwfMT0H1s9zcEGPPwHJNjt_A)

[editable source](https://mermaid-js.github.io/mermaid-live-editor/edit/#pako:eNqVVEtv4jAQ_iuWz0W9c1stbbWHbhFw5DLEEzJax07HDqss4b_vOCQQXlLLBSX6XuP5nL3OvEE91cgzgi1DuXZKfh-8BUf_IJJ36tBOJn6vlsg7ynCq1roEB1sMa_0ltK-QIT6C-w7-FvMwgwgBY6Jk3oW6_BalYm_q7HuUemMpFEfOY9b4XaJRUBUwuqj8GO3zu9btQxEwJTkKEZnc9sta7a3W-_zjebGa_1C5ZxULVJIO0sN3RCRQolYWnEt5oI6FZ4rNQ9VHw7bqp69dbN7QS6OqounlCwTzWQPLwGgUuUHnCq3atgs4t5DhhYbBkDFtMKiso0ws7tCKkoQqjwFG8V4l77KR4y0HxeuRoaosiVr05wL0vQ3D8kc9Pu4dIoMLFAer3qx2Rk5tzilu2V2C9oKcC-DUzQUZ5AV-1sRYpiLdml1mS6QXS1uSwsbm5HLDsvLvgtCwA5Pt93czX3ck_Y3oX6WLkTQYc4tZlBVtmsF7dHGG2e4wKS2mrJiCkM8VXkH4c_c8Bep3GJ7_ehaAPxXiFdG8Y2TKwtCoq5t7bkIqJqOVne5QiaLnCE7mO9v_Xs1-SUMGpXEJQtIqvDXinueUEdgEV0acujz6SZco3SIj38h90ltrcSxxrY8xcqhtTE4HgdaVEPHFUPSsp5FrfNJyjfyycdnwfMT0H1s9zcEGPPwHJNjt_A)

## Transit Data Assessments

| **Name**<br>*Key(s)*| **Description** |
| :------------- |  :-------------- |
| `Provider Assessments` | Each record is an aggregated assessment for a single `organizations` which manages one or more `services` conducted using a specific set of `gtfs checks` at a specific point in time. Each record has a `Reviewer`, `Status`, and a link to the document sent to the `organizations` (if applicable) |
| `gtfs checks` | Each record represents a check that can be performed on either a(n):<ul><li>`organization` (who manages a transit service)</li><li>`gtfs dataset` as a whole, or </li><li>a `gtfs service data` record within that `gtfs dataset`. Each check has a score type of either:<ul><li>`Boolean`: yes or no</li><li>`Nominal`: with defined scores for specific criteria levels as defined in the `Scoring Criteria` field, or</li><li>`Continuous`: as defined by the `Scoring Criteria` column and the `Max Score` field.</li></ul>Further, scores for each check can be sourced by one of <ul><li>`human`: manual work</li><li>`auto`: programmable</li><li>`gtfs-trained-human`: a huma with necessary technical training, or </li><li>`combo`: of these.</li></ul>These sources are indicated in their current, near-future, and goal states in the columns `Source`, `Source: medium-term`, and `Source: goal`. |
| `gtfs-service check data` | Each record is a specific assessment of a single `gtfs checks` for a single `gtfs service data` record at a specific point in time. |
| `gtfs-dataset check data` | Each record is a specific assessment of a single `gtfs checks` for a single `gtfs dataset` record at a specific point in time. |
| `provider check data` | Each record is a specific assessment of a single `gtfs checks` for a single `organizations` which *manages* one or more `services` at a specific point in time. |
| `assessors` | List of people that can be assigned to Transit Data Assessment completion and review.  Now that these people are collaborators in AirTable we can update this to just flag the person directly. |
| `assessed transit providers` | Imported view from [Transit Service Base](#transit-service-base) which selects for organizations which `category` is either `core` or `other public transit` and `service type` is eitehr `fixed-route` or `deviated fixed-route`. |
| `WIP gtfs grading scheme` | `WIP` Each record is a specific check that can be done on a `gtfs service data` for a specific GTFS Grading Scheme version. Scoring for the check should be based on the field `Scoring Criteria`. |
| `WIP gtfs grades` | `WIP` Each record is a specific assessment of a single datapoint within a `gtfs service data` for a specific `gtfs grading scheme` check at a specific point in time. The `Score` field is backed up by `comments supporting score` and `gtfs dataset text`, `official reference` and `official reference attach.` (for screen shots) so that identified issues can be more easily remedied by transit providers.  |
| `WIP data improvement strategy` | `WIP` Each record is a single data improvement strategy for a single `Organizations` which responds to a single `provider gtfs assessments`.  Fields includes links to the documents, `Status`, and dates. |

### Transit Data Assessments: Entity Relationship Diagram

[![](https://mermaid.ink/img/pako:eNqtlMty2zAMRX8Fw7XdD9Cuk6RZtjPOUhtIhCxMKdLDh1vH8r8X1MNRYsdJO9VKA4IHF5cEj6p2mlShyN8zbj12pS0tyPfDuz1r8l9DoBA6sjFA79brvocxRPrJow0c58xQQKmmtQCxJXh8-rYB10Agv-dagh1a3JKG6lCqG2X6ocy8dNdS_fMeI2b-nbMR2QZg2zjfYWRnofGuuwU8CdAd4TE2IXMCxf_D7EfmZmzv88zX1PM-OIm_rh-YQ3BwNGU3a8-RPOOAAJyFXevo3yhve_g7yrsNjSbdujC0R5MwChcjIOwc2yimQeSOPmxzwZ7WCzgDP2husXeRE14BRsScNqd8pi30dOW2X5DyVXf9O0JK5akxVMeBATor1xTE_-oqdbl71NgvrcvAioyzW5lO93Jsl6LGMV8Kye0ghFQJRyZ6Bb9arlvI4YZ_k16D86Jtz-KbXo8h71KkL7BLleHaHNa4RzZYGSFZDU2yWrrIvy8-AU5aYDeb-bbJs8uzzO9-i5afhwm7pTW0LhkpQucD1jcNnPCL2DzbFwU85VNiux1evZ3nDr2cjlqpjmT2WcsDe8ylSiUJ-V5njKYGk4lZxElS004OmB40R-dV0aAJtFKYotscbK2K6BPNSdNTPWWd_gBy8g8g)](https://mermaid-js.github.io/mermaid-live-editor/edit/#pako:eNqtlMty2zAMRX8Fw7XdD9Cuk6RZtjPOUhtIhCxMKdLDh1vH8r8X1MNRYsdJO9VKA4IHF5cEj6p2mlShyN8zbj12pS0tyPfDuz1r8l9DoBA6sjFA79brvocxRPrJow0c58xQQKmmtQCxJXh8-rYB10Agv-dagh1a3JKG6lCqG2X6ocy8dNdS_fMeI2b-nbMR2QZg2zjfYWRnofGuuwU8CdAd4TE2IXMCxf_D7EfmZmzv88zX1PM-OIm_rh-YQ3BwNGU3a8-RPOOAAJyFXevo3yhve_g7yrsNjSbdujC0R5MwChcjIOwc2yimQeSOPmxzwZ7WCzgDP2husXeRE14BRsScNqd8pi30dOW2X5DyVXf9O0JK5akxVMeBATor1xTE_-oqdbl71NgvrcvAioyzW5lO93Jsl6LGMV8Kye0ghFQJRyZ6Bb9arlvI4YZ_k16D86Jtz-KbXo8h71KkL7BLleHaHNa4RzZYGSFZDU2yWrrIvy8-AU5aYDeb-bbJs8uzzO9-i5afhwm7pTW0LhkpQucD1jcNnPCL2DzbFwU85VNiux1evZ3nDr2cjlqpjmT2WcsDe8ylSiUJ-V5njKYGk4lZxElS004OmB40R-dV0aAJtFKYotscbK2K6BPNSdNTPWWd_gBy8g8g)

[editable source](https://mermaid-js.github.io/mermaid-live-editor/edit/#pako:eNqtlMty2zAMRX8Fw7XdD9Cuk6RZtjPOUhtIhCxMKdLDh1vH8r8X1MNRYsdJO9VKA4IHF5cEj6p2mlShyN8zbj12pS0tyPfDuz1r8l9DoBA6sjFA79brvocxRPrJow0c58xQQKmmtQCxJXh8-rYB10Agv-dagh1a3JKG6lCqG2X6ocy8dNdS_fMeI2b-nbMR2QZg2zjfYWRnofGuuwU8CdAd4TE2IXMCxf_D7EfmZmzv88zX1PM-OIm_rh-YQ3BwNGU3a8-RPOOAAJyFXevo3yhve_g7yrsNjSbdujC0R5MwChcjIOwc2yimQeSOPmxzwZ7WCzgDP2husXeRE14BRsScNqd8pi30dOW2X5DyVXf9O0JK5akxVMeBATor1xTE_-oqdbl71NgvrcvAioyzW5lO93Jsl6LGMV8Kye0ghFQJRyZ6Bb9arlvI4YZ_k16D86Jtz-KbXo8h71KkL7BLleHaHNa4RzZYGSFZDU2yWrrIvy8-AU5aYDeb-bbJs8uzzO9-i5afhwm7pTW0LhkpQucD1jcNnPCL2DzbFwU85VNiux1evZ3nDr2cjlqpjmT2WcsDe8ylSiUJ-V5njKYGk4lZxElS004OmB40R-dV0aAJtFKYotscbK2K6BPNSdNTPWWd_gBy8g8g)

## Transit Stacks

| **Name**<br>*Key(s)*| **Description** |
| :------------- |  :-------------- |
| `products`<br><br>  *Primary Field*: `Name` | Each record is a product used in a transit technology stack at another organization (e.g. fixed-route scheduling software) or by riders (e.g. Google Maps).  Products have properties such as input/output capabilities. <br><br>Products MAY:<ul><li>*function as* one or more `stack components` |
| `contracts`<br><br> *Primary Field*: `Name` | Each record is a contract between `organizations` to either provide one or more `products` or operate one or more `services`.  Each contract has properties such as execution date, expiration, and renewals.  |
| `components` | Each component represents a single *lego* in a transit technology stack.  It is part of a single `Component Group` (e.g. CAD/AVL) which are often bundled together, which in turn is part of a `Function Group` (e.g. Fare collection ,scheduling, etc) and is operated in physical space defined in `Location` (e.g. Cloud, Vehicle, etc.) |
| `service-components` | Each record is an association between one or more `services`, a `product`, and one or more `components` which that product is serving as. |
| `relationships service-components` | Each record is an one-way association between two `organization stack components` (`Component A` and `Component B`) using a `data schemas` and `Mechanism` (e.g. `auto-triggered pull`, `intra-product`, `human transaction`, etc.) |
| `data schemas` | Each record indicates a data schema which  can be used in one or more `relationships service-components`. |
| `organizations` | Imported from [California Transit Base](#california-transit).|
| `services` | Imported from [California Transit Base](#california-transit).|

### Transit Stacks: Entity Relationship Diagram

[![](https://mermaid.ink/img/pako:eNqdk7tuwzAMRX9F0JzH7jXp0ClF09ELITGyAFs0KClFG-ffS7_6SNu0iEbp3MtLSjppQxZ1oZG3HhxDUwYla8cOgn-F5ClEde6WSzqpPfLRGyxUqRsI4DCW-kecBnxDITGY1PP0HP4PV1Tb6_QDk80jHLGuB3jEp4wbaloKGJIoVqvuS3YfVY5oVSLV1hDWYy9rapEh4Vz3N6NPpcUoSlQF8bqoU-8bk0wa9cH9JbwYi-hapqO3ffaKKbvqo-9HrMcRVb79ZtZ1Q4rL_d50x975AEOcOJ4rMwNzulvNn4Adpht9pwlsIcHeVNhA73gfxSUENEmGkKOkLrVe6Aa5AW_lHZ9651InEchV9hKLB8j1UPMsaG6t3PKd9YlYFweoIy405ET7l2B0kTjjDE0_YqLOb7JEHuQ)](https://mermaid-js.github.io/mermaid-live-editor/edit/#pako:eNqdk7tuwzAMRX9F0JzH7jXp0ClF09ELITGyAFs0KClFG-ffS7_6SNu0iEbp3MtLSjppQxZ1oZG3HhxDUwYla8cOgn-F5ClEde6WSzqpPfLRGyxUqRsI4DCW-kecBnxDITGY1PP0HP4PV1Tb6_QDk80jHLGuB3jEp4wbaloKGJIoVqvuS3YfVY5oVSLV1hDWYy9rapEh4Vz3N6NPpcUoSlQF8bqoU-8bk0wa9cH9JbwYi-hapqO3ffaKKbvqo-9HrMcRVb79ZtZ1Q4rL_d50x975AEOcOJ4rMwNzulvNn4Adpht9pwlsIcHeVNhA73gfxSUENEmGkKOkLrVe6Aa5AW_lHZ9651InEchV9hKLB8j1UPMsaG6t3PKd9YlYFweoIy405ET7l2B0kTjjDE0_YqLOb7JEHuQ)

[editable source](https://mermaid-js.github.io/mermaid-live-editor/edit/#pako:eNqdk7tuwzAMRX9F0JzH7jXp0ClF09ELITGyAFs0KClFG-ffS7_6SNu0iEbp3MtLSjppQxZ1oZG3HhxDUwYla8cOgn-F5ClEde6WSzqpPfLRGyxUqRsI4DCW-kecBnxDITGY1PP0HP4PV1Tb6_QDk80jHLGuB3jEp4wbaloKGJIoVqvuS3YfVY5oVSLV1hDWYy9rapEh4Vz3N6NPpcUoSlQF8bqoU-8bk0wa9cH9JbwYi-hapqO3ffaKKbvqo-9HrMcRVb79ZtZ1Q4rL_d50x975AEOcOJ4rMwNzulvNn4Adpht9pwlsIcHeVNhA73gfxSUENEmGkKOkLrVe6Aa5AW_lHZ9651InEchV9hKLB8j1UPMsaG6t3PKd9YlYFweoIy405ET7l2B0kTjjDE0_YqLOb7JEHuQ)

## Dashboards

## DAGs Maintenance

You can find further information on DAGs maintenance for Transit Database data [on this page](transit-database-dags).
