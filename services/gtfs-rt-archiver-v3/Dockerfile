FROM python:3.9

LABEL org.opencontainers.image.source https://github.com/cal-itp/data-infra

RUN apt-get update -y \
    && apt-get install -y python3 python3-pip

RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python3 -
ENV PATH="${PATH}:/root/.poetry/bin"

WORKDIR /app

COPY ./pyproject.toml /app/pyproject.toml
COPY ./poetry.lock /app/poetry.lock
RUN poetry config virtualenvs.create false
RUN poetry install
RUN pip install memray

COPY . /app

CMD ["python3", "-m", "--help"]
