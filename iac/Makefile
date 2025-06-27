TARGETS := init upgrade plan apply fmt migrate-state

PATHS := $(wildcard */.)

$(TARGETS): $(PATHS)
$(PATHS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

.PHONY: $(TARGETS) $(PATHS)
