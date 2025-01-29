FROM  python:3.11-buster AS build

LABEL org.opencontainers.image.source=https://github.com/cal-itp/data-infra

RUN apt-get update
RUN apt-get install -y ca-certificates curl gnupg
RUN mkdir -p /etc/apt/keyrings
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update \
    && apt-get install -y nodejs libgdal-dev libgraphviz-dev graphviz-dev

RUN npm install -g --unsafe-perm=true --allow-root netlify-cli

RUN curl -sSL https://install.python-poetry.org | python3 -
ENV PATH="/root/.local/bin:${PATH}"
RUN poetry self add poetry-plugin-export@1.9.0

RUN mkdir /app
WORKDIR /app

COPY ./pyproject.toml /app/pyproject.toml
COPY ./poetry.lock /app/poetry.lock
RUN poetry export -f requirements.txt --without-hashes --output requirements.txt \
    && pip install -r requirements.txt
RUN pip install memray

COPY ./dbt_project.yml /app/dbt_project.yml
COPY ./packages.yml /app/packages.yml
COPY ./profiles.yml /app/profiles.yml
RUN dbt deps

COPY . /app

CMD ["dbt", "run", "--project-dir", "/app", "--profiles-dir", "/app"]
