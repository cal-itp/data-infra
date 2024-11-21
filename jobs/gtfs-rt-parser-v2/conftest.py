def pytest_addoption(parser):
    parser.addoption(
        "--gcs",
        action="store_true",
        default=False,
        help="Run tests requiring GCS",
    )
