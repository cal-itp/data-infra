# Transit Database

The Cal-ITP Airtable Transit Database stores key relationships about how transit services are organized and operated in California as well as how well they are performing. See Evan to get a link and gain access.

There are two main Airtable bases:

| **Base** | **Description** |
| :------------ | :-------------- |
| [**California Transit**](#california-transit) | Defines key organizational relationships and properties. Organizations, geography, funding programs,  transit services, service characteristics, transit datasets such as GTFS, and the intersection between transit datasets and services.
| [**Transit Technology Stacks**](#transit-technology-stacks) | Defines operational setups at transit provider organizations. Defines relationships between vendor organizations, transit provider and operator organizations, products, contracts to provide products, transit stack components, and how they relate to one-another.

Important Airtable documentation is maintained elsewhere:

* [Airtable Data Documentation Google Doc](https://docs.google.com/document/d/1KvlYRYB8cnyTOkT1Q0BbBmdQNguK_AMzhSV5ELXiZR4/edit#heading=h.u7y2eosf0i1d) - this document contains documentation about data fields in Airtable.
* [California Transit Data - Operating Procedures Google Doc](https://docs.google.com/document/d/1IO8x9-31LjwmlBDH0Jri-uWI7Zygi_IPc9nqd7FPEQM/edit#) - this document outlines the processes by which Airtable data is maintained.


## Airtable things

### Primary Keys

Airtable forces the use of the left-most field as the primary key of the database: the field that must be referenced in other tables, similar to a VLOOKUP in a spreadsheet. Unlike many databases, Airtable doesn't enforce uniqueness in the values of the primary key field.  Instead, it assigns it an underlying and mostly hidden unique [`RECORD ID`](https://support.airtable.com/hc/en-us/articles/360051564873-Record-ID), which can be exposed by creating a formula field to reference it.

For the sake of this documentation, we've noted the [`Primary Field`](https://support.airtable.com/hc/en-us/articles/202624179-The-primary-field), which is not guaranteed to be unique. Some tables additionally expose the unique [`RECORD ID`](https://support.airtable.com/hc/en-us/articles/360051564873-Record-ID) as well.

### Full Documentation of Fields

AirTable does not currently have an effective mechanism to programmatically download your data schema (they have currently paused issuing keys to their metadata API). Rather than manually type-out and export each individual field definition from AirTable, please see the [AirTable-based documentation of fields](https://airtable.com/appPnJWrQ7ui4UmIl/api/docs) which is produced as a part of their API documentation. Note that you must be authenticated with access to the base to reach this link.


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

### Transit Stacks: Entity Relationship Diagram

[![](https://mermaid.ink/img/pako:eNqdk7tuwzAMRX9F0JzH7jXp0ClF09ELITGyAFs0KClFG-ffS7_6SNu0iEbp3MtLSjppQxZ1oZG3HhxDUwYla8cOgn-F5ClEde6WSzqpPfLRGyxUqRsI4DCW-kecBnxDITGY1PP0HP4PV1Tb6_QDk80jHLGuB3jEp4wbaloKGJIoVqvuS3YfVY5oVSLV1hDWYy9rapEh4Vz3N6NPpcUoSlQF8bqoU-8bk0wa9cH9JbwYi-hapqO3ffaKKbvqo-9HrMcRVb79ZtZ1Q4rL_d50x975AEOcOJ4rMwNzulvNn4Adpht9pwlsIcHeVNhA73gfxSUENEmGkKOkLrVe6Aa5AW_lHZ9651InEchV9hKLB8j1UPMsaG6t3PKd9YlYFweoIy405ET7l2B0kTjjDE0_YqLOb7JEHuQ)](https://mermaid-js.github.io/mermaid-live-editor/edit/#pako:eNqdk7tuwzAMRX9F0JzH7jXp0ClF09ELITGyAFs0KClFG-ffS7_6SNu0iEbp3MtLSjppQxZ1oZG3HhxDUwYla8cOgn-F5ClEde6WSzqpPfLRGyxUqRsI4DCW-kecBnxDITGY1PP0HP4PV1Tb6_QDk80jHLGuB3jEp4wbaloKGJIoVqvuS3YfVY5oVSLV1hDWYy9rapEh4Vz3N6NPpcUoSlQF8bqoU-8bk0wa9cH9JbwYi-hapqO3ffaKKbvqo-9HrMcRVb79ZtZ1Q4rL_d50x975AEOcOJ4rMwNzulvNn4Adpht9pwlsIcHeVNhA73gfxSUENEmGkKOkLrVe6Aa5AW_lHZ9651InEchV9hKLB8j1UPMsaG6t3PKd9YlYFweoIy405ET7l2B0kTjjDE0_YqLOb7JEHuQ)

[editable source](https://mermaid-js.github.io/mermaid-live-editor/edit/#pako:eNqdk7tuwzAMRX9F0JzH7jXp0ClF09ELITGyAFs0KClFG-ffS7_6SNu0iEbp3MtLSjppQxZ1oZG3HhxDUwYla8cOgn-F5ClEde6WSzqpPfLRGyxUqRsI4DCW-kecBnxDITGY1PP0HP4PV1Tb6_QDk80jHLGuB3jEp4wbaloKGJIoVqvuS3YfVY5oVSLV1hDWYy9rapEh4Vz3N6NPpcUoSlQF8bqoU-8bk0wa9cH9JbwYi-hapqO3ffaKKbvqo-9HrMcRVb79ZtZ1Q4rL_d50x975AEOcOJ4rMwNzulvNn4Adpht9pwlsIcHeVNhA73gfxSUENEmGkKOkLrVe6Aa5AW_lHZ9651InEchV9hKLB8j1UPMsaG6t3PKd9YlYFweoIy405ET7l2B0kTjjDE0_YqLOb7JEHuQ)

## Dashboards

## DAGs Maintenance

You can find further information on DAGs maintenance for Transit Database data [on this page](dags-maintenance).
