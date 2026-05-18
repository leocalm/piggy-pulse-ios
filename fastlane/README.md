fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios prepare_app_store_assets

```sh
[bundle exec] fastlane ios prepare_app_store_assets
```

Sync generated App Store screenshots into Fastlane and validate the upload package

### ios validate_app_store_assets

```sh
[bundle exec] fastlane ios validate_app_store_assets
```

Validate Fastlane screenshots and metadata without contacting App Store Connect

### ios upload_app_store_metadata

```sh
[bundle exec] fastlane ios upload_app_store_metadata
```

Upload screenshots and available metadata to App Store Connect without uploading a binary or submitting for review

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
