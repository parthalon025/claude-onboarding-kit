# Changelog

All notable changes to claude-onboarding-kit are documented here.
Format: [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)

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
