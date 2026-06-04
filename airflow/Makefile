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

WAREHOUSE_PATH := ../warehouse
WAREHOUSE_TARGET := staging

# --------------------------------------------------------------
# OS detection (Windows sets OS=Windows_NT, otherwise we assume *nix)
# --------------------------------------------------------------
ifeq ($(OS),Windows_NT)
	IS_WINDOWS := 1
else
	IS_WINDOWS := 0
endif

restart: sync
	uv run composer-dev restart

start: sync
	uv run composer-dev start

stop:
	uv run composer-dev stop

sync: $(WAREHOUSE_PATH)/target/manifest.json $(COMPOSER_ENVIRONMENT_PATH)
	rsync -ar plugins/ $(COMPOSER_ENVIRONMENT_PATH)/plugins/
	rsync -ar $(WAREHOUSE_PATH)/ $(COMPOSER_ENVIRONMENT_PATH)/data/warehouse/
	cp -f requirements-dev.txt $(COMPOSER_ENVIRONMENT_PATH)/requirements.txt
	# copy the base .development.env
	cp -f .development.env $(COMPOSER_ENVIRONMENT_PATH)/variables.env
ifneq (,$(wildcard .env))
	cat .env >> $(COMPOSER_ENVIRONMENT_PATH)/variables.env
endif
	# If we are on Windows, force COMPOSER_CONTAINER_RUN_AS_HOST_USER=False
	# The later definition overwrites the earlier one when the env file is read.
ifneq ($(IS_WINDOWS),0)
	@echo COMPOSER_CONTAINER_RUN_AS_HOST_USER=False >> $(COMPOSER_ENVIRONMENT_PATH)/variables.env
endif

$(WAREHOUSE_PATH)/target/manifest.json:
	cd $(WAREHOUSE_PATH) && \
	uv sync && \
	uv run dbt deps && \
	uv run dbt compile --target $(WAREHOUSE_TARGET)

$(COMPOSER_PATH):
	mkdir $(COMPOSER_PATH)

$(COMPOSER_ENVIRONMENT_PATH): $(COMPOSER_PATH)
	uv run composer-dev create \
		--from-image-version $(COMPOSER_VERSION) \
		--project $(COMPOSER_PROJECT) \
		--port 8080 \
		--dags-path dags/ \
		--database postgresql \
		$(COMPOSER_ENVIRONMENT_NAME)

pools:
	uv run composer-dev run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set airtable_pool 4 ""
	uv run composer-dev run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set external_table_pool 4 ""
	uv run composer-dev run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set rt_parse_pool 1 ""
	uv run composer-dev run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set rt_validate_pool 1 ""
	uv run composer-dev run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set schedule_parse_pool 4 ""
	uv run composer-dev run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set schedule_unzip_pool 4 ""
	uv run composer-dev run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set schedule_validate_pool 4 ""
	uv run composer-dev run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set schedule_download_pool 4 ""
	uv run composer-dev run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set littlepay_list_pool 4 ""
	uv run composer-dev run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set littlepay_download_pool 4 ""
	uv run composer-dev run-airflow-cmd \
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
	uv run composer-dev remove --skip-confirmation
	rm -r $(COMPOSER_PATH)
