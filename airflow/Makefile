COMPOSER_ENVIRONMENT_PATH := composer/cal-itp-data-infra-development
DATA_PATH := $(COMPOSER_ENVIRONMENT_PATH)/data
WAREHOUSE_PATH := $(DATA_PATH)/warehouse

clean:
ifneq (,$(wildcard $(WAREHOUSE_PATH)))
	rm -r $(WAREHOUSE_PATH)
endif

install: clean
	rsync -ar plugins $(DATA_PATH)
	rsync -ar ../warehouse $(WAREHOUSE_PATH)

start: install
	composer-dev start

restart: install
	composer-dev restart

stop:
	composer-dev stop
