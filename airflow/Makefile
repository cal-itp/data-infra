COMPOSER_ENVIRONMENT_PATH := composer/cal-itp-data-infra-development
DATA_PATH := $(COMPOSER_ENVIRONMENT_PATH)/data
WAREHOUSE_PATH := $(DATA_PATH)/warehouse
PLUGINS_PATH := $(COMPOSER_ENVIRONMENT_PATH)/plugins

clean:
ifneq (,$(wildcard $(WAREHOUSE_PATH)))
	rm -r $(WAREHOUSE_PATH)
endif
ifneq (,$(wildcard $(PLUGINS_PATH)))
	rm -r $(PLUGINS_PATH)
endif

..warehouse/target/manifest.json:
	cd ${WAREHOUSE_PATH} && poetry install && poetry run dbt deps && poetry run dbt compile --target dev

install: ../warehouse/target/manifest.json
	rsync -ar plugins/ $(PLUGINS_PATH)
	rsync -ar ../warehouse/ $(WAREHOUSE_PATH)

start: install
	composer-dev start

restart: install
	composer-dev restart

stop:
	composer-dev stop
