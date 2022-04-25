FROM openjdk:11

ENV GTFS_VALIDATOR_JAR=/gtfs-realtime-validator.jar
ENV GTFS_VALIDATOR_VERSION=v1.0.0

WORKDIR /

LABEL org.opencontainers.image.source https://github.com/cal-itp/data-infra


RUN apt-get update -y \
    && apt-get install -y python3 python3-pip

RUN wget \
    https://s3.amazonaws.com/gtfs-rt-validator/travis_builds/gtfs-realtime-validator-lib/1.0.0-SNAPSHOT/gtfs-realtime-validator-lib-1.0.0-SNAPSHOT.jar \
    -O ${GTFS_VALIDATOR_JAR}

# Python deps and app
ADD requirements.txt ./requirements.txt
RUN python3 -m pip install -r requirements.txt
RUN mkdir /app
WORKDIR /app
COPY . /app
ADD . ./

CMD ["python3", "gtfs_rt_validator_api.py", "--help"]
