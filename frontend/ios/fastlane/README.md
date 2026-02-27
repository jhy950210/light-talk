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

### ios release

```sh
[bundle exec] fastlane ios release
```

Create certificates, profiles, build and upload to TestFlight

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Upload existing IPA to TestFlight

### ios metadata

```sh
[bundle exec] fastlane ios metadata
```

Upload metadata to App Store Connect

### ios submit_review

```sh
[bundle exec] fastlane ios submit_review
```

Submit latest build for App Store review

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
