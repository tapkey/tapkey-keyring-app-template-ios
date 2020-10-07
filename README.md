# Introduction 
This project contains the source code for the _Tapkey Keyring App Template for iOS_.

# Getting Started


## 1. Install build dependencies

This project uses some ruby base build dependencies, like cocoapods and fastlane. The used version are managed and fixed via Bundler.

``` bash
bundle install
```

## 2. Install runtime dependencies

For runtime dependencies like TapkeyMobileLib is used. Use the via bundler installed cococoapod cli for installing these dependencies.

``` bash
bundle exec pod install
```

# Environments

This project supports two different environments, `production` and `sandbox` which are not interoperable. E.g. locking devices from the `production` environment can not be used with an sandbox app.

# Configurables

The _Tapkey Keyring App Template for iOS_ contains various configurable settings which can be modified according to your setup. This section explains the different configuration options and discusses their respective impacts.

* `app/App/BuildSettings.xcconfig`: Common build settings
* `app/App/env/[environment]`: Environment specific configurations 
    * `app/App/env/[environment]/EnvBuildSettings.xcconfig`: Environment specific build settings
    * `app/App/env/[environment]/AppConfiguration.swift`: Environment specific runtime settings
    * `app/App/env/[environment]/Google-Service-Info.plist`: Environment speficic google/firebase settings
* `app/App/Constants/Constants.swift`: Coloring and theming settings

## Team Id

For developing and building a valid Apple Team Id must be configured. Use the setting `DEVELOPMENT_TEAM` in the common build setting file `app/App/BuildSettings.xcconfig`. This configures the Team Id for the whole workspace.

## App Name

The Name of the App can be configured environment depending in `app/App/env/[environment]/EnvBuildSettings.xcconfig` with the setting `APP_NAME`.

## Bundle Identifier

The Bundle Identifier of the App can be configured environment depending in `app/App/env/[environment]/EnvBuildSettings.xcconfig` with the setting `BUNDLE_IDENTIFIER`.

## Sentry
Sentry is a real-time error monitoring tool which allows you to see which errors occur in the field. Once you create a Sentry account you can access the Sentry DSN value, which you need to copy over to the `sentryDSN` of `app/App/env/[environment]/AppConfiguration.swift`. Errors will be logged into the configured project.

## Tapkey Base URI

The `tapkeyBaseUri` in `app/App/env/[environment]/AppConfiguration.swift` defines the endpoint to access the Tapkey API.

## Tapkey Authorization Endpoint

This setting defines the endpoint where the app is able to exchange the Firebase token for the Tapkey token. The URI-value for `tapkeyAuthorizationEndpoint` must be an SSL-secured endpoint ("HTTPS") otherwise the app won't run.

## Tapkey OAuth Client ID

The `tapkeyOAuthClientId` in `app/App/env/[environment]/AppConfiguration.swift` defines the ID of the OAuth client that has been created on the self-service registration page.

## Tapkey Identity Provider ID

The `tapkeyIdentityProviderId` in `app/App/env/[environment]/AppConfiguration.swift` defines the ID of the identity provider that has been created on the self-service registration page.

## Tapkey Domain ID

The `tapkeyDomainId` in `app/App/env/[environment]/AppConfiguration.swift` is used to separate independent solutions based on the same Tapkey technology. The ID is assigned by Tapkey. Ask Tapkey to get your Domain ID.

## Firebase

Download and copy the `GoogleService-Info.plist` to configure Firebase to `app/App/env/[environment]/GoogleService-Info.plist`
for sandbox and production environment.

Configure the google reversed client id via `GOOGLE_REVERSED_CLIENT_ID` in `app/App/env/[environment]/EnvBuildSettings.xcconfig`.

## Provisioning Profile

The App should be signed with a `Apple Push Notification` enabled provisioning profile. Firbase Authentication uses Apple Push Notifications for validating the client. Otherwise an captcha has to be solved by the user.

# Coloring and Theming

Coloring can be adapt in `app/App/Constants/Constants.swift`.

Images are stored in `app/App/ResourcesAssets.xcassets` and configured in `app/App/Constants/Constants.swift`

## Configurable strings

The standard Android file `app/App/Resources/[language].lproj/Localizable.strings` contains all relevant string values. Values that may/should be changed are:

`tos_url` - URI to open when tapping the terms and conditions string
`address` - Your company's address

## Versioning

Versioning of the app is steered by the `app/App/BuildSettings.xcconfig` file. You may setup major, minor and revision codes.

```
1.2.3
^ ^ ^
| | |__________.
| |_____.	   |
|		|      |
Major Minor Revision
```

These settings modify the Info.plist `CFBundleShortVersionString` and `CFBundleVersion` settings. The version name will be displayed on the about screen: "Version 1.2.3"