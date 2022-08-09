# Wrapper for the MobilityData GTFS Schedule validator

This image exists to faciliate a pod operator executing a Java JAR which validates
GTFS Schedule zipfiles and outputs the resulting notices (i.e. violations). The
JAR in this folder is sourced from https://github.com/MobilityData/gtfs-validator/
and is currently v2.0.0 of that project.

Note that unlike `gtfs-rt-parser`, this code does NOT include any parsing/unzipping
of the underlying data. The RT code was written prior to substantial changes to
`calitp-py` and therefore bundles together shared functionality that will eventually
live in `calitp-py`.
