# gtfs-rt-archiver-v3

This is the third iteration of our GTFS RT downloader aka archiver.

## Redis
This application uses a task queue framework called [huey](https://github.com/coleifer/huey)
and currently uses [Redis](https://github.com/redis/redis) as the storage backend
for huey. Currently we deploy a single Redis instance per environment namespace
(e.g. `gtfs-rt-v3`, `gtfs-rt-v3-dev`) with _no disk space_ and _no horizontal scaling_.
In addition, the RT archiver relies on having low I/O latency with Redis to
minimize the latency of fetch starts. Due to these considerations, these Redis
instances should **NOT** be used for any other applications.
