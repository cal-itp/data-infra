from prometheus_client import Summary, Counter, Gauge

TICKS = Counter(name="ticks", documentation="Ticks triggered by the scheduler.")
HANDLE_TICK_PROCESSING_TIME = Summary(
    name="handle_tick_processing_time_seconds",
    documentation="Time spent processing a single tick.",
    labelnames=("url",),
)
FEEDS_IN_PROGRESS = Gauge(
    name="feeds_in_progress",
    documentation="Feeds currently being downloaded/uploaded.",
    labelnames=("url",),
)
FEEDS_DOWNLOADED = Counter(
    name="downloaded_feeds",
    documentation="Feeds sucessfully downloaded.",
    labelnames=("url",),
)
