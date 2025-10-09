.PHONY: clean clean-postgres pools restart setup start stop sync teardown

COMPOSER_ENVIRONMENT_SOURCE := calitp-staging-composer
COMPOSER_ENVIRONMENT_NAME := calitp-development-composer
COMPOSER_PATH := composer
COMPOSER_ENVIRONMENT_PATH := $(COMPOSER_PATH)/$(COMPOSER_ENVIRONMENT_NAME)

COMPOSER_VERSION := composer-2.9.7-airflow-2.9.3
COMPOSER_PROJECT := cal-itp-data-infra-staging
COMPOSER_LOCATION := us-west2

WAREHOUSE_PATH := ../warehouse
WAREHOUSE_TARGET := staging

restart: sync
	poetry run composer-dev restart

start: sync
	poetry run composer-dev start

stop:
	poetry run composer-dev stop

sync: $(WAREHOUSE_PATH)/target/manifest.json $(COMPOSER_ENVIRONMENT_PATH)
	rsync -ar plugins/ $(COMPOSER_ENVIRONMENT_PATH)/plugins/
	rsync -ar $(WAREHOUSE_PATH)/ $(COMPOSER_ENVIRONMENT_PATH)/data/warehouse/
	cp -f requirements.txt $(COMPOSER_ENVIRONMENT_PATH)/requirements.txt
	cp -f .development.env $(COMPOSER_ENVIRONMENT_PATH)/variables.env
ifneq (,$(wildcard .env))
	cat .env >> $(COMPOSER_ENVIRONMENT_PATH)/variables.env
endif

$(WAREHOUSE_PATH)/target/manifest.json:
	cd $(WAREHOUSE_PATH) && \
	poetry install && \
	poetry run dbt deps && \
	poetry run dbt compile --target $(WAREHOUSE_TARGET)

$(COMPOSER_PATH):
	mkdir $(COMPOSER_PATH)

$(COMPOSER_ENVIRONMENT_PATH): $(COMPOSER_PATH)
	poetry run composer-dev create \
		--project $(COMPOSER_PROJECT) \
		--from-source-environment $(COMPOSER_ENVIRONMENT_SOURCE) \
		--location $(COMPOSER_LOCATION) \
		--port 8080 \
		--dags-path dags/ \
		--database postgresql \
		$(COMPOSER_ENVIRONMENT_NAME)

pools:
	poetry run composer-dev run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set airtable_pool 4 ""
	poetry run composer-dev run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set external_table_pool 4 ""
	poetry run composer-dev run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set rt_parse_pool 1 ""
	poetry run composer-dev run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set rt_validate_pool 1 ""
	poetry run composer-dev run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set schedule_parse_pool 4 ""
	poetry run composer-dev run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set schedule_unzip_pool 4 ""
	poetry run composer-dev run-airflow-cmd \
		$(COMPOSER_ENVIRONMENT_NAME) \
		pools set schedule_validate_pool 4 ""

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
	rm -r $(COMPOSER_PATH)
