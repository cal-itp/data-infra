# Rotating LittlePay AWS Account Keys
> Some of this is taken from the provided Littlepay documentation, with Cal-ITP specific content added.

LittlePay requests that clients accessing their raw data feeds through S3 rotate the IAM keys every 90 days. They provide general instructions for doing so with the `aws` CLI tool. The following gives additional context on the Cal-ITP setup, and should be used in conjunction with those instructions.

## Setup

You'll need to install the `aws` CLI locally, and [configure a profile](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-quickstart.html) for each Littlepay `merchant_id` (aka `account name` or `instance` in Littlepay).

Access keys can be found in one of the two following locations.
* [Google Cloud Secret Manager](https://console.cloud.google.com/security/secret-manager?project=cal-itp-data-infra) - Search for secrets of the format `LITTLEPAY_AWS_IAM_<MERCHANT_ID>_ACCESS_KEY`; secret names are uppercase, and we have removed hyphens (or convert to underscore) in the `merchant_id` historically.
* (Deprecated) [VaultWarden](https://vaultwarden.jarv.us/#/vault) - Search for "_aws_" and you should see several entries with names that match the format "_Cal-ITP Littlepay AWS IAM Keys (<merchant_id>)_").

You can confirm you have access by listing the keys for the specific instance using the profile:
`aws iam list-access-keys --user-name <username> --profile <profile>`. **Note that the username may not be exactly the same as the `merchant_id`; check the key JSON or error output for the username.** For example, `An error occurred (AccessDenied) when calling the ListAccessKeys operation: User: arn:aws:iam::840817857296:user/system/sbmtd-default is not authorized to perform: iam:ListAccessKeys on resource: user sbmtd because no identity-based policy allows the iam:ListAccessKeys action` indicates that the username is `sbmtd-default`.

## Create and store new credentials
Secret Manager allows multiple versions of secrets, so create a new version of each secret (the access key ID and the secret key) and paste the new key as the value.

`aws iam create-access-key --user-name <username> --profile <profile>`

You could also use the CLI to create new versions of secrets, but the web UI is very easy to use.

`gcloud secrets versions add ...`

## Disable old credentials and test new credentials
Disable (*do not destroy*) the old versions in Secret Manager and test the `sync_littlepay` Airflow DAG, which is the primary integration with Littlepay in the v2 pipeline.

(Legacy) You may also need to change the credentials in any Data Transfer jobs that are still configured to read Littlepay data.

## Delete old credentials from AWS
Assuming all tests succeed, delete the old credentials from AWS.
`aws iam delete-access-key --access-key-id <old-access-key-id> --profile <profile>`
