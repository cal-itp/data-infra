GIT_DIR     := $(shell git rev-parse --absolute-git-dir)
SRC_DIR     := $(shell pwd)
HOOKS       := $(shell find "$(SRC_DIR)" -type f ! -name Makefile -exec basename {} \;)
HOOKS_DIR   := $(GIT_DIR)/hooks
HOOKS_DESTS := $(foreach h,$(HOOKS),$(HOOKS_DIR)/$(h))
$(info $(HOOKS_DESTS))

install: $(HOOKS_DESTS)

uninstall:
	find "$(GIT_DIR)/hooks" -type l -exec rm -vf {} +

reinstall: uninstall install

$(HOOKS_DIR)/%:
	ln -s "$(SRC_DIR)/$(@F)" "$@"

.PHONY: install uninstall reinstall
