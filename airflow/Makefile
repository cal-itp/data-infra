.PHONY: clean clean-postgres pools restart setup start stop sync teardown

COMPOSER_ENVIRONMENT_NAME := calitp-development-composer
COMPOSER_PATH := composer
COMPOSER_ENVIRONMENT_PATH := $(COMPOSER_PATH)/$(COMPOSER_ENVIRONMENT_NAME)

COMPOSER_PROJECT := cal-itp-data-infra-staging
# create composer-dev either with --from-image-version $(COMPOSER_VERSION)
COMPOSER_VERSION := composer-3-airflow-2.10.5-build.36
# or with --from-source-environment $(COMPOSER_ENVIRONMENT_SOURCE) --location $(COMPOSER_LOCATION)
# COMPOSER_ENVIRONMENT_SOURCE := calitp-staging-composer
# COMPOSER_LOCATION := us-west2

COMPOSER_CMD := uv run --no-project --with composer-dev composer-dev

WAREHOUSE_PATH := ../warehouse
WAREHOUSE_TARGET := staging

# --------------------------------------------------------------
# OS detection (Windows sets OS=Windows_NT, otherwise we assume *nix)
# --------------------------------------------------------------
ifeq ($(OS),Windows_NT)
	IS_WINDOWS := 1
	UNAME_S := Windows
else
	IS_WINDOWS := 0
	UNAME_S := $(shell uname -s)
endif

restart: sync
	$(COMPOSER_CMD) restart

start: sync
	$(COMPOSER_CMD) start

stop:
	$(COMPOSER_CMD) stop

sync: $(WAREHOUSE_PATH)/target/manifest.json $(COMPOSER_ENVIRONMENT_PATH)
	rsync -ar plugins/ $(COMPOSER_ENVIRONMENT_PATH)/plugins/
	rsync -ar $(WAREHOUSE_PATH)/ $(COMPOSER_ENVIRONMENT_PATH)/data/warehouse/
	# Install the SAME requirements the staging Composer 3 env deploys
	# (terraform feeds airflow/requirements-c3.txt to pypi_packages_c3), so the
	# local env mirrors staging-c3 rather than a dev-only requirements file.
	cp -f requirements-c3.txt $(COMPOSER_ENVIRONMENT_PATH)/requirements.txt
	# copy the base .development.env
	cp -f .development.env $(COMPOSER_ENVIRONMENT_PATH)/variables.env
ifneq (,$(wildcard .env))
	cat .env >> $(COMPOSER_ENVIRONMENT_PATH)/variables.env
endif
	# Configure the container user per-OS (appended last so the later
	# definition wins when the env file is read).
	#   Linux / WSL: run as the host user so files written into dags/, data/
	#     and logs/ are owned by you (host uid, not always 1000).
	#   macOS & Windows: run as the in-image airflow(999) user. Docker Desktop
	#     maps uids transparently there, and the host-user mapping otherwise
	#     breaks the image entrypoint (it chowns /home/airflow to the host user
	#     and then its own non-root `cp` can no longer write -> container exits).
ifneq ($(IS_WINDOWS),0)
	@echo COMPOSER_CONTAINER_RUN_AS_HOST_USER=False >> $(COMPOSER_ENVIRONMENT_PATH)/variables.env
else ifeq ($(UNAME_S),Darwin)
	@echo COMPOSER_CONTAINER_RUN_AS_HOST_USER=False >> $(COMPOSER_ENVIRONMENT_PATH)/variables.env
else
	@echo COMPOSER_CONTAINER_RUN_AS_HOST_USER=True >> $(COMPOSER_ENVIRONMENT_PATH)/variables.env
	@echo COMPOSER_HOST_USER_NAME=$(shell id -un) >> $(COMPOSER_ENVIRONMENT_PATH)/variables.env
	@echo COMPOSER_HOST_USER_ID=$(shell id -u) >> $(COMPOSER_ENVIRONMENT_PATH)/variables.env
endif

$(WAREHOUSE_PATH)/target/manifest.json:
	cd $(WAREHOUSE_PATH) && \
	uv sync && \
	uv run dbt deps && \
	uv run dbt compile --target $(WAREHOUSE_TARGET)

$(COMPOSER_PATH):
	mkdir $(COMPOSER_PATH)

$(COMPOSER_ENVIRONMENT_PATH): $(COMPOSER_PATH)
	$(COMPOSER_CMD) create \
		--from-image-version $(COMPOSER_VERSION) \
		--project $(COMPOSER_PROJECT) \
		--port 8080 \
		--dags-path dags/ \
		--database postgresql \
		$(COMPOSER_ENVIRONMENT_NAME)

pools:
	$(COMPOSER_CMD) run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set airtable_pool 4 ""
	$(COMPOSER_CMD) run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set external_table_pool 4 ""
	$(COMPOSER_CMD) run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set rt_parse_pool 1 ""
	$(COMPOSER_CMD) run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set rt_validate_pool 1 ""
	$(COMPOSER_CMD) run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set schedule_parse_pool 4 ""
	$(COMPOSER_CMD) run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set schedule_unzip_pool 4 ""
	$(COMPOSER_CMD) run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set schedule_validate_pool 4 ""
	$(COMPOSER_CMD) run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set schedule_download_pool 4 ""
	$(COMPOSER_CMD) run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set littlepay_list_pool 4 ""
	$(COMPOSER_CMD) run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set littlepay_download_pool 4 ""
	$(COMPOSER_CMD) run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set littlepay_parse_pool 4 ""

setup: $(COMPOSER_ENVIRONMENT_PATH)

clean-postgres:
ifneq (,$(wildcard $(COMPOSER_ENVIRONMENT_PATH)/postgresql_data))
	rm -r $(COMPOSER_ENVIRONMENT_PATH)/postgresql_data
endif

clean:
ifneq (,$(wildcard $(COMPOSER_ENVIRONMENT_PATH)/data))
	rm -r $(COMPOSER_ENVIRONMENT_PATH)/data
endif
ifneq (,$(wildcard $(COMPOSER_ENVIRONMENT_PATH)/plugins))
	rm -r $(COMPOSER_ENVIRONMENT_PATH)/plugins
endif
ifneq (,$(wildcard $(COMPOSER_ENVIRONMENT_PATH)/requirements.txt))
	rm -r $(COMPOSER_ENVIRONMENT_PATH)/requirements.txt
endif
ifneq (,$(wildcard $(COMPOSER_ENVIRONMENT_PATH)/variables.env))
	rm -r $(COMPOSER_ENVIRONMENT_PATH)/variables.env
endif

teardown: stop
	$(COMPOSER_CMD) remove --skip-confirmation
	rm -r $(COMPOSER_PATH)
