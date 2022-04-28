FROM openjdk:11

LABEL org.opencontainers.image.source https://github.com/cal-itp/data-infra

ENV GTFS_RT_VALIDATOR_JAR=/gtfs-realtime-validator.jar
ENV GTFS_VALIDATOR_VERSION=v1.0.0

RUN apt-get update -y \
    && apt-get install -y python3 python3-pip

RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3 -
ENV PATH="${PATH}:/root/.poetry/bin"

RUN wget \
    https://s3.amazonaws.com/gtfs-rt-validator/travis_builds/gtfs-realtime-validator-lib/1.0.0-SNAPSHOT/gtfs-realtime-validator-lib-1.0.0-SNAPSHOT.jar \
    -O ${GTFS_RT_VALIDATOR_JAR}

WORKDIR /app

COPY ./pyproject.toml /app/pyproject.toml
COPY ./poetry.lock /app/poetry.lock
RUN poetry config virtualenvs.create false
RUN poetry install

COPY . /app

CMD ["python3", "wrapper.py", "--help"]
