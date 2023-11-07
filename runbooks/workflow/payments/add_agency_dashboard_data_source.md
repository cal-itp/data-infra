# Onboarding New Agencies to Metabase

## Adding a New Agency Data Source to Metabase

As new agencies are introduced to the contactless payments program we will want to be able to access their data within Metabase. Because we use a [row access policy](https://github.com/cal-itp/data-infra/blob/main/warehouse/macros/create_row_access_policy.sql) in the warehouse code to limit access to data to authorized parties, this is a multi-step process and doesn't happen automatically.

### Create a new service account and row access policy

1. To begin, create a new service account for the agency within the Google Cloud Platform console, which will be used to allow Metabase read-access to the agency's payments data.

- Navigate to: <https://console.cloud.google.com/iam-admin/serviceaccounts>
- Select `+ Create Service Account` in the top-center of the page
- Populate the `Service account ID` field using the convention: `[agency-name]-payments-user`, then select `Create and Continue`
- Within the `Grant this service account access to the project` section, assign the role `Agency Payments Service Reader`
- Select `Done`

2. Download the service account key for the service account you've just created

- After selecting `Done` in the previous section, you'll be returned to the list of existing service accounts, where you should click into the service account that you just created
- Select `Keys` from the top-center of the page, and then select the `Add Key` dropdown and the `Create new key` selection within that
- Keep the default key type `JSON` and select `Create`
- This will download a JSON copy of the service accout key to your local environment, which will be used in later steps within Metabase

3. Open a new branch and edit the [create_row_access_policy macro](https://github.com/cal-itp/data-infra/blob/main/warehouse/macros/create_row_access_policy.sql)

Duplicate an existing row access policy within the file and append to the bottom of the file, before the `{% endmacro %}` text. The contents of the policy you're duplicating should look like this:

```
{{ create_row_access_policy(
    filter_column = 'participant_id',
    filter_value = '[agency-name]',
    principals = ['serviceAccount:`agency-name`-payments-user@cal-itp-data-infra.iam.gserviceaccount.com']
) }};
```

Substitute the following fields with the appropriate information for the agency that you are adding:

- `filter_value` which is the Littlepay `participant_id` for the agency
- `principals` which is the email address for the service account that was created in the previous step

Open a PR and merge these changes. If you'd like access to the results of this policy before the next time the `transform_warehouse` DAG is run, you will need to run it manually.

### Add a new `Database` in Metabase for the agency

This creates the limited-access connection the the BigQuery warehouse.

1. Navigate to Metabase, then `Settings`

In the upper-right hand corner, select the `Settings` wheel icon. Within the dropdown, select `Admin settings`.

2. In the top menu, select the `Databases` section to add a new databse

Select `Add database` in the top-right. Replace the following information:

- `Database type` --> BigQuery
- `Display name` --> `Payments - [agency name]`
- `Service account JSON file` --> upload the file downloaded in the previous section
- `Datasets` --> `Only these...`
- `Comma separated names of datasets that should appear in Metabase` --> `mart_payments`

Then `Save` your changes

3. Add a new user `Group` for the agency

This step will limit the users that can access the previously created database.

- Navigate to `People` in the top menu bar
- Select `Groups` in the left-hand menu
  - Select `Create a group` and input `Payments Group - [agency name]`
- Add users to this new group
  - If they have already have Metabase user accounts:
    - From within the `Groups` section, select the group that was just created
    - From there, select `Add members` from the top-right of the page
    - Type their name in the prompt, and once it auto-populates select `Add`
  - If they don't have Metabase user accounts:
    - Select `People` in the left-hand menu
    - Select `Invite someone` from the top-right of the page
    - Populate `First name`, `Last name`, `Email`
    - In the `Groups` dropdown, select the new agency group that was created in the previous step.

4. Create a new `Collection` for the agency

This is the folder for the agency within Metbase where we will store their payments dashboard and the questions that comprise it

- From the previous step, select `Exit Admin` in the top right-hand corner, then select `+ New` in the top right-hand corner
  - Select `Collection` from the drop-down
  - Input the name as `Payments Collection - [agency name]`
  - Collection it's saved in --> `Our Analytics` (the default)

5. Limit the access permissions on the new `Collection` by using the `Group` created in step #3

- Navigate back to `Settings --> Admin settings` in the upper right-hand corner
  - Select `Permissions` from the top menu
  - Select `Collections` from the top left-hand side
  - Click on the payments collection that you just created
  - In the dropdown to the right of `Payments Group - [agency name]`, select `View`
  - In the dropdown to the right of  `Payments Team`, select `Curate`. This will allow the internal team to manage the dashboard and questions.

Now, any questions or dashboards that you create within the collection that was created will only be able to be viewed by the agency representatives that you added to the group that was created, and managed by the larger payments team within Cal-ITP.

## Creating a New Agency Dashboard and the Comprising Questions

Relevant Metabase Concepts:

- `Question` - Individual visualizations
- `Dashboard` - Made up of `Question` and text tiles
- `Collection` - An agency-specific 'folder' within Metabase where agency `Dashboards` and `Questions` live.

Creation of collections and permissions groups are explained in the previous documentation section.

1. Duplicate an existing dashboard

The easiest way to create a new dashboard for an agency in Metabase is to duplicate an existing dashboard into the new agency's `Collection`. By duplicating the dashboard into the permission-protected collection, you are ensuring that only representatives from that agency (and internal staff) are able to view the data.

At this time there are two different types of agency dashboards: those that use flat fare formats and those that use variable fare formats. There are currently none that use both. These differences impact a few questions within the dashboards, but the majority of the dashboards is the same. Some dashboards do have custom questions as requested by agencies, and currently one agency excludes certain questions (CCJPA doesn't include any `Form Factor` related questions due to only accepting one type).

Good source dashboards for copying:

- Flat Fare: Humboldt Transit Authority
- Variable Fare: Redwood Coast Transit

To duplicate a dashboard, navigate to the collection of one of the source dashboards above

- The dashboard should be pinned to the top of the collection, when hovering your cursor over the dashboard a menu icon should appear
- Select the menu icon, and select `Duplicate` in the dropdown
- In the window that appears:
  - In the `Name` field, subsitute the name of the new agency in the parentheses and remove ` - Duplicate` which was appended to the end
  - in the `Which collection should this go in` dropdown, select the Collection of the new agency
  - **DO NOT** select the `Only duplicate the dashboard` box, which is not selected by default
  - Select `Duplicate` to create the duplicate dashboard and questions

Like mentioned previously, Metabase Dashboards are comprised of `Questions` which serve as the visualizations in the dashboards. By not selecting the `Only duplicate the dashboard` box, the Questions will also be copied into the Collection along with the Dashboard during the duplication process.

2. Re-configuring the copied questions to use the correct `Database`

Duplicating an existing dashboard preserves much of the text, formatting, and settings of the dashboard -- and saves a lot of work as compared to creating a new dashboard from scratch. Unfortunately, within the duplicated questions there is a lot of re-configuring that must be done when switching the question to use the new agency's `Database` within Metabase, created in the previous documentation section.

You will need to open every question in the new dashboard and change the source table used. This will reset all of the components of the `Question` which will need to be replaced.

The easiest way to do this is to pull up the collection of the agency whose dashboard you initially duplicated and the new agency's collection side-by-side. Go down the lists, opening up each question. Change the Database and table name of the new agency's question to use the new agency's version of the Database and table, and then change the question's configuration to match the original question. Thankfully, question visualization configurations like visualization type (bar, line) and axis labels should mostly be preserved.

**For SQL-based questions**

You will only need to change the name of the Database, the table name is explicit in the query.

However, you will need to change the settings of the field being used as the time filter

- Navigate to edit the SQL-based question, and select the `Variables` icon to the right of the query text.
- From here, modify the variable settings:
  - `Variable Type` --> `Field Filter`
  - `Field to Map to` --> navigate to the table being used in the query (`FCT PAYMENTS RIDES V2`) and select the `On Transaction Date Time Pacific` field
  - `Filter widget type` --> `Date Filter`

Once you've re-configured the question, you can press save, selecting `Replace original question` when prompted (the default).

3. Configure the dashboard `Time Window` filter widget

Once the questions are updated, the remaining step is to configure them to be filtered by the dashboard filter widget.

- Navigate to the dashboard, select the `Edit dashboard` icon in the top-right
- Select the settings wheel that appears next to the `Time Window` widget in the top-left of the dashboard
- This will cause a dropdown menu to display within all the Question tiles of the dashboard, except for SQL-based questions which have already had the filter applied in the previous step and will not have a drop-down menu displayed.
- Within the dropdowns, select `On Transaction Date Time Pacific` for all of the questions except the exceptions below
  - `Settlement Requested Date Time Utc` for:
    - `Total Revenue`
    - `Total Revenue by Day`
    - `Number of Settled Refunds, Grouped by Week`
    - `Value of Settled Refunds, Grouped by Week`
  - `Week Start` for
    - `Journeys with Unlabeled Routes`
