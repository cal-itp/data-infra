FROM openjdk:11

LABEL org.opencontainers.image.source https://github.com/cal-itp/data-infra

RUN apt-get update -y \
    && apt-get install -y python3 python3-pip python3-venv

RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/install-poetry.py | python3 -
ENV PATH="/root/.local/bin:${PATH}"

ENV GTFS_SCHEDULE_VALIDATOR_JAR=/gtfs-validator-3.1.1-cli.jar
ENV GTFS_SCHEDULE_VALIDATOR_VERSION=v3.1.1
RUN curl https://github.com/MobilityData/gtfs-validator/releases/download/v3.1.1/gtfs-validator-3.1.1-cli.jar > ${GTFS_SCHEDULE_VALIDATOR_JAR}

WORKDIR /app

COPY ./pyproject.toml /app/pyproject.toml
COPY ./poetry.lock /app/poetry.lock
RUN poetry export -f requirements.txt --without-hashes --output requirements.txt \
    && pip install -r requirements.txt
RUN pip install memray

COPY . /app

CMD ["python3", "-m", "gtfs_schedule_validator", "--help"]
