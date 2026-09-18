from alert_urls import caltrans_sso_log_url

COMPOSER_LOG_URL = "https://1d19bb0b084f4d598c29f826e4459a04-dot-us-west2.composer.googleusercontent.com/dags/dbt_all/grid?dag_run_id=scheduled__2026-09-07T14%3A00%3A00%2B00%3A00&task_id=dbt_all.warehouse_test&base_date=2026-09-07T14%3A00%3A00%2B0000&tab=logs"

# click-tested end to end: signs in via the dot-ca-gov workforce provider and
# lands on the byoid twin of COMPOSER_LOG_URL
EXPECTED_SSO_URL = "https://auth.cloud.google/signin/locations/global/workforcePools/dot-ca-gov/providers/dot-gcp?continueUrl=https%3A%2F%2Fus-west2.composer.cloud.google%2F_signin%3Fcontinue%3Dhttps%253A%252F%252F1d19bb0b084f4d598c29f826e4459a04-dot-us-west2.composer.byoid.googleusercontent.com%252Fdags%252Fdbt_all%252Fgrid%253Fdag_run_id%253Dscheduled__2026-09-07T14%25253A00%25253A00%25252B00%25253A00%2526task_id%253Ddbt_all.warehouse_test%2526base_date%253D2026-09-07T14%25253A00%25253A00%25252B0000%2526tab%253Dlogs%26endpoint%3D1d19bb0b084f4d598c29f826e4459a04"


def test_composer_log_url_is_rewritten_through_caltrans_sso():
    assert caltrans_sso_log_url(COMPOSER_LOG_URL) == EXPECTED_SSO_URL


def test_non_composer_log_urls_pass_through_unchanged():
    for log_url in [
        "http://localhost:8080/dags/dbt_all/grid?tab=logs",
        "https://example.com/log?execution_date=2026-09-07",
        "https://foo-dot-us-west2.composer.example.com/dags/dbt_all/grid",
    ]:
        assert caltrans_sso_log_url(log_url) == log_url
