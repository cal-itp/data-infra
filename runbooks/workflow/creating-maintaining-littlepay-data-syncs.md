# Creating and Maintaining Littlepay Data Syncs

> Some of this is taken from [the provided Littlepay documentation](https://docs.littlepay.io/data/faq/), with Cal-ITP specific content added. The documentation site is login-protected, and credentials are available in the Cal-ITP Vaultwarden vault.

We access Littlepay data via AWS S3 file storage, and [use Airflow-orchestrated sync tasks to bring that data into Cal-ITP's GCS buckets and then into our data warehouse](https://docs.calitp.org/data-infra/architecture/data.html).

## Setting Up a New Littlepay Sync

### Prerequisites

In order to access source data from Littlepay, you will need a vendor-provided AWS access key for the agency you're setting up. To request access to Littlepay data feeds, contact support@littlepay.com. You will receive an email from Littlepay support, which will include your support ticket reference as well as the next steps for you. Littlepay will provision your access and send your AWS access key through email.

Examples of access keys for existing Littlepay data syncs can be found in [Google Cloud Secret Manager](https://console.cloud.google.com/security/secret-manager?project=cal-itp-data-infra).

You'll need to install the `aws` CLI locally, and [configure a profile](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html) for each Littlepay `merchant_id` (aka `account name` or `instance` in Littlepay).

You can confirm you have access to a given access key by listing the keys for the specific instance using the profile you configured:
`aws iam list-access-keys --user-name <username> --profile <profile>`. **Note that the username may not be exactly the same as the `merchant_id`; check the key JSON or error output for the username.** For example, `An error occurred (AccessDenied) when calling the ListAccessKeys operation: User: arn:aws:iam::840817857296:user/system/sbmtd-default is not authorized to perform: iam:ListAccessKeys on resource: user sbmtd because no identity-based policy allows the iam:ListAccessKeys action` indicates that the username is `sbmtd-default`.

### First-Time Setup Steps

When you receive an access key from Littlepay for an agency that is being newly synced, you need to add that access key to Google Cloud Secret Manager, named with the format `LITTLEPAY_AWS_IAM_<MERCHANT_ID>_ACCESS_KEY` like the existing keys. Secret names are uppercase, and we have removed hyphens (or convert to underscore) in the `merchant_id` historically.

Next, [create a service account in the cal-itp-data-infra project](https://console.cloud.google.com/iam-admin/serviceaccounts/create?walkthrough_id=iam--create-service-account&project=cal-itp-data-infra#step_index=1) specifically for this agency's Littlepay sync, using the naming convention `<MERCHANT_ID>-payments-user`. There is a pre-configured role titled Agency Payments Service User, which will give the new service account the correct permissions when assigned to that account.

After that, you should create a sync task (configured via a small YAML file) in [the sync-littlepay DAG folder in the data-infra repository](https://github.com/cal-itp/data-infra/tree/8516a1a4ab2ecfe6ef33e3fbc4224bcedbd06e98/airflow/dags/sync_littlepay), structurally similar to the others that are there, utilizing the instance name and access key name for the agency you're setting up. Similarly, you should create a parse task (configured via another YAML file) corresponding to the new agency in [the parse-littlepay DAG folder](https://github.com/cal-itp/data-infra/tree/8516a1a4ab2ecfe6ef33e3fbc4224bcedbd06e98/airflow/dags/parse_littlepay). Then, add a mapping between the agency's instance identifier and its Cal-ITP internal GTFS dataset identifier in [this seed file](https://github.com/cal-itp/data-infra/blob/main/warehouse/seeds/payments_entity_mapping.csv).

[This pull request](https://github.com/cal-itp/data-infra/pull/2928/files) demonstrates all four of the code changes involved in this setup process (though the row-level access policy setting is now in a macro [here](https://github.com/cal-itp/data-infra/blob/main/warehouse/macros/create_row_access_policy.sql#L21), rather than in the `fct_payments_rides_v2` model).

After these steps are completed, the new Littlepay account's data should start flowing after the [Littlepay sync DAG](https://b2062ffca77d44a28b4e05f8f5bf4996-dot-us-west2.composer.googleusercontent.com/dags/sync_littlepay/grid), the [Littlepay parse DAG](https://b2062ffca77d44a28b4e05f8f5bf4996-dot-us-west2.composer.googleusercontent.com/dags/parse_littlepay/grid), the [external table Airflow DAG](https://b2062ffca77d44a28b4e05f8f5bf4996-dot-us-west2.composer.googleusercontent.com/dags/create_external_tables/grid), and the [warehouse transformation DAG](https://b2062ffca77d44a28b4e05f8f5bf4996-dot-us-west2.composer.googleusercontent.com/dags/transform_warehouse/grid) all run.

## Rotating Littlepay AWS Keys

Littlepay requests that clients accessing their raw data feeds through S3 rotate the IAM keys every 90 days. AWS provides [general instructions for doing so with the `aws` CLI tool](https://aws.amazon.com/blogs/security/how-to-rotate-access-keys-for-iam-users/). The following gives additional context on the Cal-ITP setup, and should be used in conjunction with those instructions.

### Create and store new credentials

First, follow the instructions linked above to create a new set of AWS keys for the client. The command you use to do so will look something like this:

`aws iam create-access-key --user-name <username> --profile <profile>`

Google Secret Manager allows you to store multiple versions of the same secret as you update the secret's value over time. Once you've created an updated key in AWS using the instructions above, [create a new version of the corresponding secret in Secret Manager](https://cloud.google.com/secret-manager/docs/add-secret-version) and paste the new AWS key as the value stored inside the new version of the secret (following the same format as the existing keys).

If you prefer, you can use the Google Cloud CLI to create new versions of secrets, but [the web UI](https://console.cloud.google.com/security/secret-manager?project=cal-itp-data-infra) contains the same functionality:

`gcloud secrets versions add ...`

### Disable old credentials and test new credentials

[Disable (*do not destroy*) the old versions in Secret Manager](https://cloud.google.com/secret-manager/docs/disable-secret-version) and test the `sync_littlepay` Airflow DAG, which is the primary integration with Littlepay in the v2 pipeline.

### Delete old credentials from AWS

Assuming all tests succeed, delete the old credentials from AWS.
`aws iam delete-access-key --access-key-id <old-access-key-id> --profile <profile>`
