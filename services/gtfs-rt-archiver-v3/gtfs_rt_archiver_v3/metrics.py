from prometheus_client import Histogram, Counter

FEEDS_DOWNLOADED = Counter(
    name="downloaded_feeds",
    documentation="Feeds successfully downloaded.",
    labelnames=("url",),
)
FEED_REQUEST_FAILURES = Counter(
    name="feed_request_failures",
    documentation="Exceptions raised during download_feed calls",
    labelnames=("url",),
)
FETCH_PROCESSED_BYTES = Counter(
    name="fetch_processed_bytes",
    documentation="Count of bytes fully handled (i.e. down/upload).",
    labelnames=("url",),
)
FETCH_PROCESSING_DELAY = Histogram(
    name="fetch_processing_delay_seconds",
    documentation="The slippage between a tick and download start of a feed.",
    labelnames=("url",),
)
FETCH_PROCESSING_TIME = Histogram(
    name="fetch_processing_time_seconds",
    documentation="Time spent processing a single fetch.",
    labelnames=("url",),
)
TICKS = Counter(
    name="ticks",
    documentation="Ticks triggered by the scheduler.",
)
TASK_SIGNALS = Counter(
    name="huey_task_signals",
    documentation="All huey task signals.",
    labelnames=("signal", "exc_type"),
)
