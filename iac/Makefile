TARGETS := init plan apply

PATHS := $(wildcard */.)

$(TARGETS): $(PATHS)
$(PATHS):
	$(MAKE) -C $@ $(MAKECMDGOALS)

.PHONY: $(TARGETS) $(PATHS)
