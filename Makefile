.PHONY: lint validate test install

lint:
	@echo "Running shellcheck on all .sh files..."
	@find . -name "*.sh" -not -path "./_archived/*" -not -path "./node_modules/*" \
	  | sort | xargs shellcheck && echo "shellcheck: all clean"

validate:
	@bash tests/validate.sh

test: validate lint

install:
	@bash install.sh
