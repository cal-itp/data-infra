.PHONY: clean sync setup start restart stop

COMPOSER_ENVIRONMENT_NAME := calitp-development-composer
COMPOSER_ENVIRONMENT_PATH := composer/$(COMPOSER_ENVIRONMENT_NAME)
DATA_PATH := $(COMPOSER_ENVIRONMENT_PATH)/data

COMPOSER_VERSION := composer-2.8.6-airflow-2.6.3
COMPOSER_PROJECT := cal-itp-data-infra-staging

clean:
ifneq (,$(wildcard $(DATA_PATH)))
	rm -r $(DATA_PATH)
endif

sync:
	rsync -ar plugins/ $(COMPOSER_ENVIRONMENT_PATH)/plugins/
	rsync -ar ../warehouse/ $(DATA_PATH)/warehouse/
	cp -f requirements.txt $(COMPOSER_ENVIRONMENT_PATH)/requirements.txt
	cp -f .development.env $(COMPOSER_ENVIRONMENT_PATH)/variables.env
	cat .env >> $(COMPOSER_ENVIRONMENT_PATH)/variables.env

create: clean sync
	poetry run composer-dev create --from-image-version $(COMPOSER_VERSION) --project $(COMPOSER_PROJECT) --port 8080 --dags-path dags/ --database postgresql $(COMPOSER_ENVIRONMENT_NAME)

start: clean sync
	poetry run composer-dev start

restart: clean sync
	poetry run composer-dev restart

stop:
	poetry run composer-dev stop

teardown: stop clean
	rm -r $(COMPOSER_ENVIRONMENT_PATH)
