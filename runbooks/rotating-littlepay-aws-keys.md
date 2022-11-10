# Rotating LittlePay AWS Account Keys

LittlePay requests that clients accessing their raw data feeds through S3 rotate the IAM keys every 90 days. They provide general instructions for doing so with the `aws` CLI tool. The following gives additional context on the Cal-ITP setup, and should be used in conjunction with those instructions.

0.  **Pre-requisites**

    You'll to install the `aws` CLI locally, and to configure profiles for each Littlepay `merchant_id` (the account names in LittlePay). To set up a profile, follow the instructions at https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html. You can find the access key id and secret for each `merchant_id` in [VaultWarden](https://vaultwarden.jarv.us/#/vault) (search for "_aws_" and you should see several entries with names that match the format "_Cal-ITP Littlepay AWS IAM Keys (<merchant_id>)_").

1.  **Creating new AWS credentials**

    Follow the instructions provided by LittlePay for rotating the account keys. Keep track of the JSON from the key creation steps, as you'll be storing these in VaultWarden later. After creating a new access key for each account and **before deleting the old credentials, test the credentials** by:
    * Replacing the key and secret in your own local configuration and ensuring that listing keys using the `aws` CLI still works. You should see two keys listed for each account instead of one.
    * Replacing the access key and secret in the data transfer tasks on Google Cloud. Manually re-run the tasks to ensure they complete successfully. Each one should only take a minute or so.

3.  **Updating records of AWS credentials**

    Assuming all tests succeed, overwrite the notes in VaultWarden with the new credentials (the JSON as returned in the key creation step) and run the key deletion step in from LittlePay's instructions.
