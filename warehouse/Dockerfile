FROM python:3.9-buster

LABEL org.opencontainers.image.source https://github.com/cal-itp/data-infra

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get update \
  && apt-get install -y nodejs libgdal-dev libgraphviz-dev graphviz-dev

RUN npm install -g --unsafe-perm=true --allow-root netlify-cli

RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="/root/.local/bin:${PATH}"

RUN mkdir /app
WORKDIR /app

COPY ./pyproject.toml /app/pyproject.toml
COPY ./poetry.lock /app/poetry.lock
RUN poetry export -f requirements.txt --without-hashes --output requirements.txt \
    && pip install -r requirements.txt

COPY ./dbt_project.yml /app/dbt_project.yml
COPY ./packages.yml /app/packages.yml
COPY ./profiles.yml /app/profiles.yml
RUN dbt deps

COPY . /app

CMD ["dbt", "run", "--project-dir", "/app", "--profiles-dir", "/app"]
