.PHONY: lint lint-sh

all: lint

lint: lint-sh

lint-sh:
	shellcheck scripts/*.sh plugins/*.sh hooks/*.sh install.sh uninstall.sh
