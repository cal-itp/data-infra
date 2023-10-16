# Creating and Maintaining Littlepay Data Syncs

> Some of this is taken from the provided Littlepay documentation, with Cal-ITP specific content added.

We access Littlepay data via AWS S3 file storage, and use Airflow-orchestrated sync tasks to bring that data into Cal-ITP's GCS buckets and then into our data warehouse.

## Setting Up a New Littlepay Sync

### Prerequisites

In order to access source data from Littlepay, you will need a vendor-provided AWS access key for the agency you're setting up. Examples of access keys for existing Littlepay data syncs can be found in [Google Cloud Secret Manager](https://console.cloud.google.com/security/secret-manager?project=cal-itp-data-infra).

You'll need to install the `aws` CLI locally, and [configure a profile](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html) for each Littlepay `merchant_id` (aka `account name` or `instance` in Littlepay).

You can confirm you have access to a given access key by listing the keys for the specific instance using the profile you configured:
`aws iam list-access-keys --user-name <username> --profile <profile>`. **Note that the username may not be exactly the same as the `merchant_id`; check the key JSON or error output for the username.** For example, `An error occurred (AccessDenied) when calling the ListAccessKeys operation: User: arn:aws:iam::840817857296:user/system/sbmtd-default is not authorized to perform: iam:ListAccessKeys on resource: user sbmtd because no identity-based policy allows the iam:ListAccessKeys action` indicates that the username is `sbmtd-default`.

### First-Time Setup Steps

When you receive an access key from Littlepay for an agency that is being newly synced, you need to add that access key to Google Cloud Secret Manager, named with the format `LITTLEPAY_AWS_IAM_<MERCHANT_ID>_ACCESS_KEY` like the existing keys. Secret names are uppercase, and we have removed hyphens (or convert to underscore) in the `merchant_id` historically.

Next, [create a service account in the cal-itp-data-infra project](https://console.cloud.google.com/iam-admin/serviceaccounts/create?walkthrough_id=iam--create-service-account&project=cal-itp-data-infra#step_index=1) specifically for this agency's Littlepay sync, using the naming convention `<MERCHANT_ID>-payments-user`. There is a pre-configured role titled Agency Payments Service User, which will give the new service account the correct permissions when assigned to that account.

After that, you should create a simple YAML file in [the sync-littlepay DAG folder in the data-infra repository](https://github.com/cal-itp/data-infra/tree/8516a1a4ab2ecfe6ef33e3fbc4224bcedbd06e98/airflow/dags/sync_littlepay), structurally similar to the others that are there, utilizing the instance name and access key name for the agency you're setting up. Similarly, you should create a YAML file corresponding to the new agency in [the parse-littlepay DAG folder](https://github.com/cal-itp/data-infra/tree/8516a1a4ab2ecfe6ef33e3fbc4224bcedbd06e98/airflow/dags/parse_littlepay). Then, add a mapping between the agency's instance identifier and its Cal-ITP internal GTFS dataset identifier in [this seed file](https://github.com/cal-itp/data-infra/blob/main/warehouse/seeds/payments_gtfs_datasets.csv).

[This pull request](https://github.com/cal-itp/data-infra/pull/2928/files) demonstrates all four of the code changes involved in this setup process (though the row-level access policy setting is now in a macro [here](https://github.com/cal-itp/data-infra/blob/main/warehouse/macros/create_row_access_policy.sql#L21), rather than in the `fct_payments_rides_v2` model)

## Rotating Littlepay AWS Keys

Littlepay requests that clients accessing their raw data feeds through S3 rotate the IAM keys every 90 days. They provide general instructions for doing so with the `aws` CLI tool. The following gives additional context on the Cal-ITP setup, and should be used in conjunction with those instructions.

### Create and store new credentials

Secret Manager allows multiple versions of secrets, so create a new version of each secret (the access key ID and the secret key) and paste the new key as the value.

`aws iam create-access-key --user-name <username> --profile <profile>`

You could also use the CLI to create new versions of secrets, but the web UI is very easy to use.

`gcloud secrets versions add ...`

### Disable old credentials and test new credentials

Disable (*do not destroy*) the old versions in Secret Manager and test the `sync_littlepay` Airflow DAG, which is the primary integration with Littlepay in the v2 pipeline.

### Delete old credentials from AWS

Assuming all tests succeed, delete the old credentials from AWS.
`aws iam delete-access-key --access-key-id <old-access-key-id> --profile <profile>`