clean:
	rm -r composer/cal-itp-data-infra-development/data/warehouse

install: clean
	rsync -ar ../warehouse composer/cal-itp-data-infra-development/data
	rsync -ar plugins composer/cal-itp-data-infra-development

start: install
	composer-dev start

restart: install
	composer-dev restart

stop:
	composer-dev stop
