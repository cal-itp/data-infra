SELECT
    Organization as organization
FROM `{{ env_var('GOOGLE_CLOUD_PROJECT') }}`.blackcat_raw.2023_organizations
