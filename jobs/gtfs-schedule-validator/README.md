# Wrapper for the MobilityData GTFS Schedule validator

This image exists to faciliate a pod operator executing a Java JAR which validates
GTFS Schedule zipfiles and outputs the resulting notices (i.e. violations). The
JARs in this folder are sourced from https://github.com/MobilityData/gtfs-validator/,
and our Python code automatically selects which version is relevant for an extract.

Note that unlike `gtfs-rt-parser`, this code does NOT include any parsing/unzipping
of the underlying data. The RT code was written prior to substantial changes to
`calitp-py` and therefore bundles together shared functionality that will eventually
live in `calitp-py`.
