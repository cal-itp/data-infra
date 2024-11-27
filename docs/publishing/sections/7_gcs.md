(publishing-gcs)=

# GCS

### Public Data Access in GCS

Some data stored in Cloud Storage is configured to be publicly accessible, meaning anyone on the internet can read it at any time. In Google Cloud Storage, you can make data publicly accessible either at the bucket level or the object level. At the bucket level, you can grant public access to all objects within the bucket by modifying the bucket policy. Alternatively, you can provide public access to specific objects.

Notes:

- Always ensure that sensitive information is not exposed when configuring public access in Google Cloud Storage. Publicly accessible data should be carefully reviewed to prevent the accidental sharing of confidential or private information.
- External users can't browse the public bucket on the web, only download individual files. If you have many files to share, it's best to use the [Command Line Interface.](https://cloud.google.com/storage/docs/access-public-data#command-line)
- There is a [function](https://github.com/cal-itp/data-analyses/blob/f62b150768fb1547c6b604cb53d122531104d099/_shared_utils/shared_utils/publish_utils.py#L16) in shared_utils that handles writing files to the public bucket, regardless of the file type (e.g., Parquet, GeoJSON, etc.)

NOTE: If you are planning on publishing to [CKAN](publishing-ckan) and you are using the dbt exposure publishing framework, your data will already be saved in GCS as part of the upload process.
