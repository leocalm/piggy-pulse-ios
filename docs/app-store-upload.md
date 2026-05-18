# App Store Upload Package

This document describes the Phase 4 workflow for preparing PiggyPulse App Store Connect screenshots and available metadata with Fastlane.

Nothing in this workflow uploads by default. Upload only happens when you explicitly run the Fastlane upload lane or `fastlane deliver`.

## What This Phase Covers

- Sync generated final screenshots into Fastlane's expected screenshot folder.
- Validate screenshots and available metadata locally.
- Provide Fastlane lanes for preparation and optional App Store Connect upload.

This phase does not build or upload a binary, submit for review, automatically release, or change production app behavior.

## Prerequisites

Generate and validate screenshots first:

```bash
./scripts/capture-raw-screenshots.sh
./scripts/validate-raw-screenshots.sh
./scripts/generate-app-store-frames.sh
./scripts/validate-final-screenshots.sh
```

Install Fastlane when you are ready to use App Store Connect:

```bash
bundle install
```

The project includes:

```text
Gemfile
fastlane/Appfile
fastlane/Deliverfile
fastlane/Fastfile
```

## Credentials

Preferred authentication is an App Store Connect API key. Do not commit the key file.

Set:

```bash
export APP_STORE_CONNECT_API_KEY_PATH="/secure/path/AuthKey_XXXXXXXXXX.json"
export APP_STORE_APP_IDENTIFIER="com.piggypulse.ios"
```

The file referenced by `APP_STORE_CONNECT_API_KEY_PATH` must be a Fastlane-compatible JSON file with the private key text embedded in the `key` field. Do not use `key_filepath` for this path; Fastlane `deliver`/Spaceship expects `key` when loading `api_key_path`.

```json
{
  "key_id": "XXXXXXXXXX",
  "issuer_id": "00000000-0000-0000-0000-000000000000",
  "key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----",
  "duration": 1200,
  "in_house": false
}
```

Optional team/account variables:

```bash
export APP_STORE_CONNECT_APPLE_ID="apple-id@example.com"
export APP_STORE_CONNECT_TEAM_ID="123456789"
export APP_STORE_TEAM_ID="ABCDE12345"
```

The default bundle identifier is `com.piggypulse.ios`.

## Metadata

Tracked metadata now includes the approved localized App Store copy:

```text
fastlane/metadata/{locale}/name.txt
fastlane/metadata/{locale}/promotional_text.txt
fastlane/metadata/{locale}/description.txt
fastlane/metadata/{locale}/keywords.txt
fastlane/metadata/{locale}/release_notes.txt
```

The following field is intentionally not created yet because approved localized copy was not provided:

- `subtitle.txt`

Add `subtitle.txt` only when approved localized subtitle copy exists.

The validation script checks that required metadata exists, that promotional text and keywords fit App Store limits, and that the privacy/security claims remain present:

- no bank connections
- no ads
- no analytics or tracking
- data is encrypted when stored
- data is stored in Europe

It also rejects references to Overlays, future-pricing promises such as "free forever", and the technical phrase "encryption at rest".

## Sync Screenshots

Generated final screenshots live under:

```text
app-store/final-screenshots/{iphone,ipad}/{locale}/
```

Sync them into Fastlane:

```bash
./scripts/sync-app-store-assets.sh
```

Output:

```text
fastlane/screenshots/{locale}/iphone-01-dashboard.png
fastlane/screenshots/{locale}/iphone-02-themes.png
fastlane/screenshots/{locale}/iphone-03-transactions.png
fastlane/screenshots/{locale}/iphone-04-periods.png
fastlane/screenshots/{locale}/iphone-05-categories.png
fastlane/screenshots/{locale}/ipad-01-dashboard.png
fastlane/screenshots/{locale}/ipad-02-themes.png
fastlane/screenshots/{locale}/ipad-03-transactions.png
fastlane/screenshots/{locale}/ipad-04-periods.png
fastlane/screenshots/{locale}/ipad-05-categories.png
```

Fastlane categorizes screenshots by image dimensions during upload. The device prefix prevents iPhone and iPad files from colliding in the same locale folder.

Generated screenshot PNGs under `fastlane/screenshots/` are ignored by Git.

Useful subset commands:

```bash
./scripts/sync-app-store-assets.sh --locale en-US
./scripts/sync-app-store-assets.sh --device-family iphone
./scripts/sync-app-store-assets.sh --clean
```

## Validate Upload Package

Validate screenshots and available metadata:

```bash
./scripts/validate-app-store-upload-package.sh
```

Validation checks:

- each required locale exists
- required metadata files exist
- `promotional_text.txt` is no more than 170 characters
- `keywords.txt` is no more than 100 characters
- required privacy/security claims are present in each locale
- Overlays, future-pricing promises, and "encryption at rest" are absent
- all required iPhone and iPad screenshots exist
- screenshot files are PNG
- screenshot dimensions are valid for the device family
- screenshot files are below the configured size limit
- no unexpected PNG files exist in Fastlane screenshot locale folders during full validation

By default, these files are required:

```text
name.txt
promotional_text.txt
description.txt
keywords.txt
release_notes.txt
```

When approved subtitle copy exists, require it during validation:

```bash
APP_STORE_REQUIRED_METADATA_FILES="name.txt subtitle.txt promotional_text.txt description.txt keywords.txt release_notes.txt" \
  ./scripts/validate-app-store-upload-package.sh
```

## Fastlane Lanes

Prepare assets without contacting App Store Connect:

```bash
bundle exec fastlane prepare_app_store_assets
```

Validate already-synced assets:

```bash
bundle exec fastlane validate_app_store_assets
```

Upload screenshots and available metadata only when explicitly ready:

```bash
bundle exec fastlane upload_app_store_metadata
```

For non-interactive automation, skip Fastlane's HTML preview prompt:

```bash
APP_STORE_DELIVER_FORCE=true bundle exec fastlane upload_app_store_metadata
```

The upload lane calls `deliver` with:

- `skip_binary_upload: true`
- `skip_screenshots: false` by default, or `true` when `APP_STORE_SKIP_SCREENSHOTS=true`
- `skip_metadata: false`
- `skip_app_version_update: true`
- `submit_for_review: false`
- `automatic_release: false`
- `run_precheck_before_submit: false`
- `screenshot_processing_timeout: 900`
- `overwrite_screenshots: false` by default
- `force: false` by default, or `true` when `APP_STORE_DELIVER_FORCE=true`

`skip_app_version_update` is intentionally true so this lane does not create or modify an App Store version number by itself. Change that only when release ownership is clear.

Precheck is disabled for this metadata/screenshot upload lane because the lane never submits for review and Fastlane cannot check in-app purchases when authenticated only with an App Store Connect API key.

To upload metadata without touching screenshots:

```bash
APP_STORE_SKIP_SCREENSHOTS=true APP_STORE_DELIVER_FORCE=true bundle exec fastlane upload_app_store_metadata
```

The lane also forces Fastlane screenshot upload concurrency to one thread because App Store Connect screenshot APIs can return transient 500s or delayed visibility when many screenshot placeholders are created at once. Override only if Apple upload stability is known to be good:

```bash
DELIVER_NUMBER_OF_THREADS=1
SPACESHIP_SCREENSHOT_UPLOAD_TIMEOUT=20
APP_STORE_SCREENSHOT_SETTLE_SECONDS=90
```

The settle wait gives App Store Connect time to make newly uploaded screenshots visible to Fastlane's checksum verification. If screenshots upload successfully but Fastlane immediately reports every file as missing, increase `APP_STORE_SCREENSHOT_SETTLE_SECONDS`.

To reduce the upload scope while troubleshooting, upload one or more locales with `APP_STORE_UPLOAD_LOCALES`:

```bash
APP_STORE_UPLOAD_LOCALES=en-US bundle exec fastlane upload_app_store_metadata
APP_STORE_UPLOAD_LOCALES=en-US,pt-PT,de-DE bundle exec fastlane upload_app_store_metadata
```

When `APP_STORE_UPLOAD_LOCALES` is set, the lane builds a temporary filtered upload package under `fastlane/.upload-scope/` and passes that filtered metadata/screenshot path to `deliver`. This is required because Fastlane's `languages` option alone does not prevent screenshot files from other locale folders from being loaded.

If a previous screenshot upload left partial or stuck screenshots in App Store Connect, run a clean replacement for a single locale:

```bash
APP_STORE_UPLOAD_LOCALES=en-US APP_STORE_OVERWRITE_SCREENSHOTS=true APP_STORE_SKIP_METADATA=true bundle exec fastlane upload_app_store_metadata
```

Use `APP_STORE_OVERWRITE_SCREENSHOTS=true` carefully: it clears existing screenshots for the selected locale/device screenshot sets before uploading the local files.

## Manual Deliver Command

Equivalent direct command:

```bash
bundle exec fastlane deliver \
  --metadata_path fastlane/metadata \
  --screenshots_path fastlane/screenshots \
  --skip_binary_upload true \
  --skip_app_version_update true \
  --submit_for_review false \
  --automatic_release false
```

Add `--api_key_path "$APP_STORE_CONNECT_API_KEY_PATH"` when using an API key directly.

## Screenshot Upload 500s

Fastlane may print:

```text
Waiting for screenshots to appear before uploading. This is unlikely to be recovered unless it's 503 error. error="Server error got 500"
```

This comes from Fastlane while creating App Store Connect screenshot upload placeholders. The local package can still be valid; the failure is usually App Store Connect returning a server error during screenshot upload.

Recommended recovery:

1. Wait a few minutes and retry the same command once.
2. If it repeats, upload a single locale with `APP_STORE_UPLOAD_LOCALES=en-US`.
3. If metadata already uploaded successfully, add `APP_STORE_SKIP_METADATA=true` for screenshot-only retries.
4. If screenshots upload but are immediately reported as missing, retry with a longer visibility wait, for example `APP_STORE_SCREENSHOT_SETTLE_SECONDS=180`.
5. If that locale has partial screenshots from the failed run, retry it with `APP_STORE_OVERWRITE_SCREENSHOTS=true`.
6. Continue locale by locale until all screenshots are uploaded.

## Safe Full Workflow

```bash
./scripts/capture-raw-screenshots.sh
./scripts/validate-raw-screenshots.sh
./scripts/generate-app-store-frames.sh
./scripts/validate-final-screenshots.sh
./scripts/sync-app-store-assets.sh
./scripts/validate-app-store-upload-package.sh
```

Then upload only when explicitly ready:

```bash
bundle exec fastlane upload_app_store_metadata
```

## Avoiding Accidental Review Submission

- Do not run `deliver --submit_for_review true`.
- Do not change `submit_for_review(false)` in `fastlane/Deliverfile`.
- Do not change `automatic_release(false)` in `fastlane/Deliverfile`.
- Keep binary upload separate from metadata/screenshot upload.
- Review Fastlane output before confirming any App Store Connect changes.
