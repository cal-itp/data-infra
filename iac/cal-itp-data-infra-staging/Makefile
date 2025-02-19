PATHS := $(shell ls -d */*)
TERRAFORM := $(shell which terraform)

define FOREACH
	for DIR in $(PATHS); do \
		$(TERRAFORM) -chdir=$$DIR $(1); \
	done
endef

.PHONY: init
init:
	$(call FOREACH,init)

.PHONY: plan
plan:
	$(call FOREACH,plan)

.PHONY: apply
apply:
	$(call FOREACH,apply)
