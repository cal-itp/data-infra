FROM eclipse-temurin:21

LABEL org.opencontainers.image.source https://github.com/cal-itp/data-infra

RUN apt-get update -y \
    && apt-get install -y python3.9 python3-pip python3-venv libunwind-dev liblz4-dev

RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="/root/.local/bin:${PATH}"

# v2 from https://github.com/MobilityData/gtfs-validator/releases/download/v2.0.0/gtfs-validator-v2.0.0_cli.jar
ENV V2_VALIDATOR_JAR=/gtfs-validator-v2.0.0_cli.jar
COPY ./gtfs-validator-v2.0.0_cli.jar ${V2_VALIDATOR_JAR}

# v3 from https://github.com/MobilityData/gtfs-validator/releases/download/v3.1.1/gtfs-validator-3.1.1-cli.jar
ENV V3_VALIDATOR_JAR=/gtfs-validator-3.1.1-cli.jar
COPY ./gtfs-validator-3.1.1-cli.jar ${V3_VALIDATOR_JAR}

# v4 from https://github.com/MobilityData/gtfs-validator/releases/download/v4.0.0/gtfs-validator-4.0.0-cli.jar
ENV V4_VALIDATOR_JAR=/gtfs-validator-4.0.0-cli.jar
COPY ./gtfs-validator-4.0.0-cli.jar ${V4_VALIDATOR_JAR}

# v4.1.0 from https://github.com/MobilityData/gtfs-validator/releases/download/v4.1.0/gtfs-validator-4.1.0-cli.jar
ENV V4_1_VALIDATOR_JAR=/gtfs-validator-4.1.0-cli.jar
COPY ./gtfs-validator-4.1.0-cli.jar ${V4_1_VALIDATOR_JAR}

# v4.2.0 from https://github.com/MobilityData/gtfs-validator/releases/download/v4.2.0/gtfs-validator-4.2.0-cli.jar
ENV V4_2_VALIDATOR_JAR=/gtfs-validator-4.2.0-cli.jar
COPY ./gtfs-validator-4.2.0-cli.jar ${V4_2_VALIDATOR_JAR}

# v5 from https://github.com/MobilityData/gtfs-validator/releases/download/v5.0.0/gtfs-validator-5.0.0-cli.jar
ENV V5_VALIDATOR_JAR=/gtfs-validator-5.0.0-cli.jar
COPY ./gtfs-validator-5.0.0-cli.jar ${V5_VALIDATOR_JAR}

# v7.1 from https://github.com/MobilityData/gtfs-validator/releases/download/v7.1.0/gtfs-validator-7.1.0-cli.jar
ENV V7_1_VALIDATOR_JAR=/gtfs-validator-7.1.0-cli.jar
COPY ./gtfs-validator-7.1.0-cli.jar ${V7_1_VALIDATOR_JAR}

WORKDIR /app

COPY ./pyproject.toml /app/pyproject.toml
COPY ./poetry.lock /app/poetry.lock
# RUN poetry self add poetry-plugin-export
# RUN poetry export -f requirements.txt --without-hashes --output requirements.txt \
#     && pip install -r requirements.txt --break-system-packages

COPY . /app

RUN poetry install --no-interaction
CMD ["poetry", "run", "python3", "-m", "gtfs_schedule_validator", "--help"]
