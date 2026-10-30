# iOS release setup

The workflow in `.github/workflows/ios-release.yml` builds a signed IPA on a
macOS GitHub runner. It runs only when manually started from **Actions → iOS
release → Run workflow**. Upload to App Store Connect is an explicit option;
the default run only builds an IPA artifact.

## One-time Apple setup

1. In Apple Developer, register the explicit App ID
   `com.agdevelps.realityshift`. Use that exact bundle ID for the app record
   in App Store Connect and for the provisioning profile. If Apple says the
   ID is unavailable, choose a new unique ID and update both the Xcode
   project and the `IOS_BUNDLE_ID` GitHub variable.
2. Create an Apple Distribution certificate and export its certificate and
   private key as a password-protected `.p12` file.
3. Create an **App Store Connect** provisioning profile for that exact App ID
   and distribution certificate. Note its exact profile name and download the
   `.mobileprovision` file.
4. Create a team App Store Connect API key with permission to upload builds.
   Keep the `.p8` private key, key ID, and issuer ID.
5. Create an iOS app record in App Store Connect before attempting upload.
6. The iOS AdMob app, Hint rewarded, and Money interstitial IDs from the
   provided AdMob screenshots are configured. The workflow rejects Google's
   sample IDs for release.

## GitHub configuration

Put these values in **Settings → Secrets and variables → Actions** for the
repository. Never commit certificate or API key files.

| Variables | Value |
| --- | --- |
| `IOS_BUNDLE_ID` | Optional override; defaults to `com.agdevelps.realityshift` |
| `APPLE_TEAM_ID` | Apple Developer team ID |
| `IOS_PROFILE_NAME` | Exact App Store Connect profile name |
| `IOS_ADMOB_APP_ID` | Optional override; defaults to `ca-app-pub-7694497723149363~4777319882` |
| `IOS_ADMOB_REWARDED_ID` | Optional override; defaults to Hint unit `ca-app-pub-7694497723149363/6627081469` |
| `IOS_ADMOB_INTERSTITIAL_ID` | Optional override; defaults to Money unit `ca-app-pub-7694497723149363/4454932430` |

| Secrets | Value |
| --- | --- |
| `BUILD_CERTIFICATE_BASE64` | Base64 contents of the `.p12` |
| `P12_PASSWORD` | Password used when exporting the `.p12` |
| `BUILD_PROVISION_PROFILE_BASE64` | Base64 contents of the `.mobileprovision` |
| `KEYCHAIN_PASSWORD` | A new random password for the runner keychain |
| `ASC_KEY_ID` | App Store Connect API key ID, needed for upload only |
| `ASC_ISSUER_ID` | App Store Connect issuer ID, needed for upload only |
| `ASC_PRIVATE_KEY` | Entire `.p8` text, needed for upload only |

On macOS, base64 encode a file with `base64 -i path/to/file | pbcopy` and paste
the resulting text into its GitHub secret.

## Release run

1. Put the project in a Git repository and push the workflow and app source to
   GitHub. This working folder currently has no `.git` directory.
2. Run the workflow with upload **off** first. Download and check the IPA
   artifact. A macOS signing failure needs the certificate/profile/team values
   corrected before an upload run.
3. Run again with upload **on** when the signed build is ready. This uploads a
   build; App Store Connect processing and App Review are separate steps.
4. Complete the app listing, screenshots, privacy details, age rating, and
   review submission in App Store Connect. The local `privacy-policy.html`
   must be hosted at a public URL if used as the app's privacy policy.

Official references: [Flutter iOS release](https://docs.flutter.dev/deployment/ios),
[GitHub signing on macOS](https://docs.github.com/en/actions/how-tos/deploy/deploy-to-third-party-platforms/sign-xcode-applications),
[Apple distribution profile](https://developer.apple.com/help/account/provisioning-profiles/create-an-app-store-provisioning-profile),
[Apple app record](https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/).
