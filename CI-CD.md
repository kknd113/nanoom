# Nanoom CI/CD plan

The initial repository upload does not enable automated builds or distribution. Add these in two small steps after the native demo builds successfully in a normal Xcode environment.

## Step 1 — Pull request checks

Use GitHub Actions with read-only repository permissions.

- Validate the Xcode project references and plist files.
- Validate the demo generator separately; never regenerate the configured Live project.
- Build the WithDemo scheme without signing on a macOS runner with an explicitly selected compatible Xcode version.
- Select an installed iPhone simulator and run WithTests.
- Keep the demo check independent of Firebase configuration and Apple account credentials.
- Cancel superseded runs for the same pull request and set job timeouts.

Start with manual workflow dispatch, then enable pull_request and main-branch push triggers once the job is reliable. Confirm runner allowance and expected usage before enabling frequent macOS runs.

## Step 2 — Manual TestFlight delivery

Add a separate manual release workflow after the live app, signing identity, and bundle ID are configured.

- Build and archive the WithLive scheme with release configuration.
- Supply signing material and App Store Connect credentials from GitHub environment secrets, never repository files.
- Store the Firebase app configuration in the chosen deployment configuration mechanism.
- Upload to TestFlight and verify processing status.
- Keep production deployment and any database rule changes separate from ordinary pull request checks.

The Live target now has working email authentication, private group creation/invitations, session restoration and 43 passing real-cloud authorization checks. Account deletion, group leave/removal, physical cleanup, privacy disclosures and real-device QA remain prerequisites for broader distribution.
