# AGENTS.md

## Purpose

This repo is the native PiggyPulse iOS client for iPhone, iPad, widgets, and Apple Watch. Agents should keep SwiftUI code aligned with AgentBrain, current source, mobile security requirements, and the calm PiggyPulse product language.

## Memory-first workflow

AgentBrain is the durable project memory source. Before meaningful work:

1. Read the memory manifest.
2. Read PiggyPulse project context.
3. Read relevant project memory files.
4. Search decisions.
5. Check open questions.
6. Inspect this repo.

If AgentBrain and code disagree, stop and report the mismatch. Top-level `Mobile.md` and `iOS.md` were not present during creation of this file; use `Repos/ios-piggypulse.md` and propose an open question if those files are still missing.

## Required memory reads

- Always: `Context.md`, `ArchitectureOverview.md`, `ProductPrinciples.md`, `KnownIssues.md`.
- iOS work: `Repos/ios-piggypulse.md`, `DesignSystem.md`, `SecurityModel.md`, `Testing.md`, `Deployment.md`, `Integrations/AppStore.md`.
- Feature work: relevant `Features/*`, especially `Auth.md`, `Dashboard.md`, `BudgetPeriods.md`, `Transactions.md`, `Accounts.md`, `Categories.md`, `Projections.md`.
- API integration: `APIConventions.md`, `DataModel.md`.

## Memory write-back rules

After meaningful work, record durable decisions, open questions, interaction/session summaries, and requested daily/global summaries.

Use MCP tools if available: `record_decision`, `upsert_open_question`, `record_interaction`, `append_daily_log`, `append_global_daily_summary`.

If MCP is unavailable, write to `AgentBrain/10_Projects/PiggyPulse/`. Do not store secrets, `.env` contents, credentials, private keys, tokens, signing material, provisioning profiles, or raw chain-of-thought.

## Repo overview

SwiftUI app targeting iOS 26+, with MVVM + Repository architecture, `@EnvironmentObject` app state, URLSession async/await networking, Bearer token auth stored in Keychain, CryptoKit encryption-at-rest support, biometrics, local notifications, widgets, and Apple Watch companion targets.

## Important directories

- `App/` - app entry point and global state.
- `Core/Models/` - Codable API/domain models.
- `Core/Network/` - `APIClient`, endpoints, errors, and token management.
- `Core/Repositories/` - data fetching and domain repositories.
- `Core/Crypto/` - encryption-at-rest and DEK handling.
- `Core/Biometrics/` - Face ID / Touch ID helpers.
- `Core/Notifications/` - notification scheduling.
- `Design/` - theme, colors, typography, spacing, and radii.
- `Features/` - feature modules for auth, dashboard, transactions, periods, budget, accounts, categories, vendors, overlays, subscriptions, settings, onboarding, and navigation.
- `PiggyPulseWatch/` - Watch app.
- `PiggyPulseWidgets/` - iOS widgets.
- `PiggyPulseTests/` and `PiggyPulseUITests/` - tests.
- `scripts/` - project maintenance and E2E helper scripts.

## Commands

Verified from `README.md`, `.github/workflows/ci.yml`, and `scripts/e2e-test.sh`.

### Install

No package manager install command is verified. Open `PiggyPulse.xcodeproj` in Xcode.

### Development

- `open PiggyPulse.xcodeproj`

### Build

- `xcodebuild build -project PiggyPulse.xcodeproj -scheme PiggyPulse -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -configuration Debug CODE_SIGNING_ALLOWED=NO`

### Test

- `xcodebuild test -project PiggyPulse.xcodeproj -scheme PiggyPulse -destination 'platform=iOS Simulator,name=iPhone 16 Pro' -configuration Debug CODE_SIGNING_ALLOWED=NO`
- `./scripts/e2e-test.sh`
- `./scripts/e2e-test.sh --setup`
- `./scripts/e2e-test.sh --teardown`

### Lint / format

No Swift lint or formatter command is verified.

### Database / migrations

Not applicable in this repo.

### Mobile platform commands

Use the Xcode commands above. Do not invent `pod`, `tuist`, `fastlane`, or Swift Package commands unless the repo adds those files.

## App Store screenshot automation

When working on screenshot automation:

- Keep production behavior unchanged.
- Screenshot/demo mode must only activate through explicit launch arguments, environment variables, or test-only configuration.
- All screenshot data must be deterministic.
- All localized screenshot copy must live in a single structured source of truth.
- Every locale must contain the same keys.
- Add validation for missing locale keys.
- Prefer existing i18n and fixture patterns already used in the app.
- Do not hardcode localized screenshot data directly inside UI components.
- Do not introduce external services for screenshot generation.
- Do not upload to App Store Connect unless explicitly requested.

### Required screenshot locales

- `en-US`
- `en-GB`
- `pt-BR`
- `pt-PT`
- `es-ES`
- `fr-FR`
- `nl-NL`
- `de-DE`

### Validation expectations

Before finishing screenshot automation work, run the relevant checks available in the repo, such as typecheck, lint, tests, and build. If a check cannot be run, explain why.

## Conventions

- Follow MVVM + Repository and existing `@EnvironmentObject` app state patterns.
- Keep models Codable and aligned with backend API casing/semantics.
- Use URLSession async/await and existing `APIClient`/`APIEndpoints`.
- Use Bearer tokens for mobile auth; do not switch iOS to web cookie assumptions without a recorded decision.
- Store tokens and sensitive material in Keychain only.
- Keep client-side decryption aligned with `SecurityModel.md` and backend encryption-at-rest behavior.
- Keep UI aligned with `Design/Theme.swift` and PiggyPulse calm, descriptive tone.
- Preserve iPhone, iPad, widget, and Watch implications when changing shared models or state.

## Testing expectations

- UI/model changes: build the `PiggyPulse` scheme for an iOS simulator.
- Networking/auth/security changes: run or update relevant unit/UI tests and inspect token refresh, Keychain, and error behavior.
- E2E changes: use `./scripts/e2e-test.sh` with a safe test backend.
- If Xcode/simulator is unavailable, state that clearly and include the exact command not run.

## Security / privacy rules

- Never commit signing certificates, provisioning profiles, private keys, `.p8` files, passwords, API tokens, or production secrets.
- Keep Keychain storage for sensitive tokens/session material.
- Do not hardcode production secrets.
- Follow `SecurityModel.md` for auth, token, and encryption changes.
- Keep API base URLs and Bearer token behavior aligned with backend/mobile decisions.
- Follow `PrivacyRules.md` only if the task touches personal/career/user memory; otherwise project security rules apply.

## Environment variables

No persistent repo environment variables are documented. The E2E script passes `E2E_API_URL` to `xcodebuild`; do not document values.

## When to stop and ask/report

Stop and report if memory contradicts source code, required commands are missing, tests fail for unrelated reasons, signing material or secrets are required, a public API/security behavior change is needed, App Store/TestFlight release assumptions are unclear, or the requested change conflicts with recorded decisions.

## Completion checklist

Before final response, verify:

- [ ] Relevant AgentBrain memory was read.
- [ ] Relevant source files were inspected.
- [ ] Existing decisions and open questions were checked.
- [ ] Commands run are listed.
- [ ] Tests/lint/build were run where appropriate, or skipped with reason.
- [ ] Durable decisions were recorded or proposed.
- [ ] Open questions were recorded or proposed.
- [ ] No secrets or `.env` values were exposed.
- [ ] Any memory/code contradictions were reported.
