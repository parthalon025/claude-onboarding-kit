# Changelog

All notable changes to claude-onboarding-kit are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

## [1.1.0](https://github.com/parthalon025/claude-onboarding-kit/compare/v1.0.0...v1.1.0) (2026-03-22)


### Features

* add Phase 2.6 CI workflow stamping to claude-init ([2f76f61](https://github.com/parthalon025/claude-onboarding-kit/commit/2f76f617cc0556a7cc27cb01c506229323804a26))
* lessons-db integration + docs/lessons scaffolding ([ed98d12](https://github.com/parthalon025/claude-onboarding-kit/commit/ed98d12beaf82a8d851e147a8e067ade41848e9c))
* lessons-db integration + docs/lessons/ scaffolding ([5b68fe9](https://github.com/parthalon025/claude-onboarding-kit/commit/5b68fe940181cb564381fe40d38ebe4365d4ed67))


### Bug Fixes

* increase embed timeout 30s→120s, gitignore .embeddings/ ([21904cd](https://github.com/parthalon025/claude-onboarding-kit/commit/21904cd1e383496ddf4f239e872a9e3277c601b1))
* **lint:** tune markdownlint/cspell configs, wire all linters to Makefile ([a404deb](https://github.com/parthalon025/claude-onboarding-kit/commit/a404deb7150710b7b2b83f7e9e3c8d4ad1ddf893))
* **plugins:** fix copy_config early exit and pipx support for Python tools ([b7ddf3d](https://github.com/parthalon025/claude-onboarding-kit/commit/b7ddf3dd1b92121d98a93b31d07ba0ef0ecf0f69))
* **plugins:** pip_install and pipx failures are now non-fatal ([d8f585e](https://github.com/parthalon025/claude-onboarding-kit/commit/d8f585e57d410c504bbf4beebadcc89b850fd977))
* replace scope tag placeholders with language defaults ([a8be98c](https://github.com/parthalon025/claude-onboarding-kit/commit/a8be98c3574b4ac9b92c1401aedee87b9cf3aeed))
* security — derive SECURITY.md email from git config, scrub local paths in plan doc ([71c3d9d](https://github.com/parthalon025/claude-onboarding-kit/commit/71c3d9d6ef3b9754bdc336a04c7cdd21fe4ee44c))

## [Unreleased]

### Added
- Mode-based project lifecycle pipeline (Internal Tool / Product / Open Source Library)
- 8 new skills: create-tech-spec, create-risk-log, create-qa-plan, create-adr,
  create-retrospective, create-mrd, create-roadmap, create-release-plan
- Pipeline status tracking (tasks/pipeline-status.md)
- Kit version tracking (VERSION file)
- goal-reflection and improvement-loop hook templates
- AGENTS.md template
- gitleaks.toml allowlist starter
- claude-init --product and --lib mode flags

### Changed
- lesson-check.sh archived — lessons-db is now canonical anti-pattern scanner
- /setup-repo Phase 7 updated to use lessons-db scan + scope inference
- CLAUDE.md templates overhauled with lessons rules, Code Factory, lean gate

### Removed
- lesson-check.sh from scripts/ (archived to _archived/)
