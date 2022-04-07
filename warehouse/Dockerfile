FROM python:3.7-buster

LABEL org.opencontainers.image.source https://github.com/cal-itp/data-infra

RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -
ENV PATH="${PATH}:/root/.poetry/bin"

RUN mkdir /app
WORKDIR /app

COPY ./pyproject.toml /app/pyproject.toml
COPY ./poetry.lock /app/poetry.lock
RUN poetry export -f requirements.txt --output requirements.txt \
    && pip install -r requirements.txt

COPY ./dbt_project.yml /app/dbt_project.yml
COPY ./packages.yml /app/packages.yml
RUN dbt deps

COPY . /app

CMD ["dbt", "run", "--project-dir", "/app", "--profiles-dir", "/app"]
