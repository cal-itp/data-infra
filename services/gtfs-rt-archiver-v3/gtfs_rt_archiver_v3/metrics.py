from prometheus_client import Counter, Gauge, Histogram

# TODO: these should probably be config_ now
standard_labels = (
    "record_name",
    "record_uri",
    "record_feed_type",
)
AIRTABLE_CONFIGURATION_AGE = Gauge(
    name="airtable_configuration_age",
    documentation="Airtable configuration age in seconds",
)
TICKS = Counter(
    name="ticks",
    documentation="Ticks triggered by the scheduler.",
)
TASK_SIGNALS = Counter(
    name="huey_task_signals",
    documentation="All huey task signals.",
    labelnames=standard_labels + ("signal", "exc_type"),
)
FETCH_PROCESSED_BYTES = Counter(
    name="fetch_processed_bytes",
    documentation="Count of bytes fully handled (i.e. down/upload).",
    labelnames=standard_labels + ("content_type",),
)
FETCH_PROCESSING_DELAY = Histogram(
    name="fetch_processing_delay_seconds",
    documentation="The slippage between a tick and download start of a feed.",
    labelnames=standard_labels,
)
FETCH_PROCESSING_TIME = Histogram(
    name="fetch_processing_time_seconds",
    documentation="Time spent processing a single fetch.",
    labelnames=standard_labels,
)
