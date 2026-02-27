.PHONY: lint lint-sh lint-yaml lint-md lint-spell lint-actions validate test install

lint: lint-sh lint-yaml lint-md lint-spell lint-actions

lint-sh:
	@echo "Running shellcheck..."
	@find . -name "*.sh" -not -path "./_archived/*" -not -path "./node_modules/*" \
	  | sort | xargs shellcheck && echo "shellcheck: all clean"

lint-yaml:
	@echo "Running yamllint..."
	@yamllint . && echo "yamllint: all clean"

lint-md:
	@echo "Running markdownlint..."
	@npx markdownlint-cli2 "**/*.md" "#node_modules" "#docs/plans" && echo "markdownlint: all clean"

lint-spell:
	@echo "Running cspell..."
	@npx cspell "**" --no-progress --quiet && echo "cspell: all clean"

lint-actions:
	@echo "Running actionlint..."
	@actionlint && echo "actionlint: all clean"

validate:
	@bash tests/validate.sh

test: validate lint

install:
	@bash install.sh
