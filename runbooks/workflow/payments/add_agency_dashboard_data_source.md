# Onboarding New Agencies to Metabase

## Adding a New Agency Data Source to Metabase

As new agencies are introduced to the contactless payments program we will want to be able to access their data in Metabase for use in their payments dashboard. Because we have a \[row access policy\](insert link) in the warehouse to limit the data that is able to be viewed by agencies while within Metabase this is a multi-step process and doesn't happen automatically.

1. To begin, create a new service account for the agency within the Google Cloud Platform console.

- Navigate to: https://console.cloud.google.com/iam-admin/serviceaccounts
- Select `+ Create Service Account` in the top-center of the page
- When naming the service account, use the convention: `[agency-name]-payments-user@cal-itp-data-infra.iam.gserviceaccount.com`
- Download the JSON service account for use later in this process

2. Duplicate an existing row access policy within the \[create_row_access_policy macro\](insert link and make sure file name is correct) and substitute the following with the appropriate information for the agency that you are adding:

- `filter_value` which is the Littlepay `participant_id` for the agency

- `principals` which is the address for the service account that was created in the previous step

- Open a PR and merge these changes

- Navigate to the service account that you created in the Google Cloud Platform console and download the key as a `.json` file and store locally on your computer

3. Add a new `Database` in Metabase for the agency
   This creates the limited-access connection the the BigQuery warehouse.

- Navigate to Metabase, then from the upper-right hand corner select the `Settings --> Admin settings` section, then the `Databases` section in the top menu
  - Select `Add database`. Replace the following information:
    - Database type --> BigQuery
    - Display name --> `Payments - [agency name]`
    - Service account JSON file --> upload the file downloaded in the previous step
    - Datasets --> `Only these...`
    - Comma separated names of datasets that should appear in Metabase --> `mart_payments`
  - Then `Save changes`

4. Add a new user `Group` for the agency
   This limits the people that can access the previously created database.

- Navigate to `People` in the top menu bar
- Select `Groups` in the left-hand menu
  - Select `Create a group` and input `Payments Group - [agency name]`
- Select `People` in the left-hand menu
  - Select `Invite someone`
  - Add representatives from the agency that you are adding
  - Select `Groups`,  and then select the new agency group that was created in the previous step.

5. Create a new `Collection` for the agency

- Select `Exit Admin` in the top right-hand corner, then select `+ New` in the top right-hand corner
  - Select `Collection` from the drop-down
  - Input the name as `Payments Collection - [agency name]`
  - Collection it's saved in --> `Our Analytics` (the default)

6. Limit the access permissions on the new `Collection`

- Navigate back to `Settings --> Admin settings` in the upper right-hand corner
  - Select `Permissions` from the top menu
  - Select `Collections` from the top left-hand side
  - Click on the payments collection that you just created
  - In the dropdown next to `Payments Collection - [agency name]` that you just created, select `View`
  - Next to the group `Payments Team`, select `Curate`

Now, any questions or dashboards that you create within the collection that was created will only be able to be viewed by the agency representatives that you added to the new group that was created, as well as the larger payments team within Cal-ITP.

## Creating a New Agency Dashboard and the Comprising Questions

Relevant Metabase Concepts:

- `Question` - Visualizations of analysis concepts
- `Dashboard` - Comprised of `Question`s and text tiles
- `Collection` - An agency-specific 'folder' within Metabase where agency `Question`s and `Dashboard`s live. Created is explained in the previous documetnation  section. Permission layers are added at the Collection level.

### Duplicating an existing dashboard

The easiest way to create a new dashboard for an agency in Metabase is to duplicate an existing dashboard into the new agency's `Collection`, created in the previous documentation section. By duplicating the dashboard into the permission-protected collection, you are ensuring that only representatives from that agency (and internal staff) are able to view the data.

At this time there are two different types of agency dashboards: those that use flat fare formats and those that use variable fare formats. There are currently none that use both. These differences impact a few questions within the dashboards, but the majority of the dashboards is the same. Some dashboards do have custom questions as requested by agencies.

Good source dashboards for copying:

- Variable Fare: CCJPA
- Flat Fare: MST

Metabase dashboards are comprised of `Questions`, which serve as the tiles in the dashboard. These will also be copied into the collection along with the dashboard during the copying process.

### Re-configuring the copied questions to use the correct `Database`

Most of the work of setting up a new dashboard is re-configuring the copied questions to use the agency-specific database created in the previous section. You will need to open every question in the new collection and change the source table. The database name will be `Payments - [agency name]`, and the table that you use within the database will be the same as the example question.

Unfortunately, this requires you to reconfigure every question. It would be suggested to open up the agency's questions that you used as a source side-by-side with the copied questions and using that as the template. Using this method (duplicating an existing dashboard, changing the source database, and reconfiguring the question) is still preferable to starting from scratch because once the questions are saved the formatting and layout of the dashboard remains.

#### How to change source database in normal questions:

#### How to change source database and filter variables in SQL questions:

#### How to update the dashboard filter:

### Configure the dashboard date `Time Window` filter widget

Once the questions are updated, the remaining step is to configure them to be filtered by the dashboard filter widget.

Navigate to the dashboard, select edit, and then click on the settings wheel next to the filter widget in the top-left hand side of the dashboard. This will display a dropdown menu within all questions. Within the dropdown, select `Transaction Date Time Pacific`. SQL-based questions have already had the filter added in the step above, and will not have a drop-down menu displayed.
