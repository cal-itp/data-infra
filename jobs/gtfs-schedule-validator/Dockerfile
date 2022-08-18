FROM openjdk:11

LABEL org.opencontainers.image.source https://github.com/cal-itp/data-infra

ENV GTFS_SCHEDULE_VALIDATOR_JAR=/gtfs-validator-v2.0.0_cli
ENV GTFS_SCHEDULE_VALIDATOR_VERSION=v2.0.0

RUN apt-get update -y \
    && apt-get install -y python3 python3-pip

RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3 -
ENV PATH="${PATH}:/root/.poetry/bin"

# formerly the "1.0.0-SNAPSHOT" from S3
COPY ./gtfs-validator-v2.0.0_cli.jar ${GTFS_SCHEDULE_VALIDATOR_JAR}

WORKDIR /app

COPY ./pyproject.toml /app/pyproject.toml
COPY ./poetry.lock /app/poetry.lock
RUN poetry config virtualenvs.create false
RUN poetry install
RUN pip install memray

COPY . /app

CMD ["python3", "-m", "gtfs_schedule_validator", "--help"]
