TARGETS := init plan apply fmt migrate-state

PATHS := $(wildcard */.)

$(TARGETS): $(PATHS)
$(PATHS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

.PHONY: $(TARGETS) $(PATHS)
