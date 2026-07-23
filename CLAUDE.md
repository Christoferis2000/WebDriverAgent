# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repository Is

WebDriverAgent (published to npm as `appium-webdriveragent`) is a WebDriver server implementation for iOS/tvOS. It has two distinct halves living in one repo:

1. **An Xcode project (Objective-C)** — the actual WebDriverAgent server that runs on an iOS/tvOS device or simulator. It links `XCTest.framework` and exposes an HTTP endpoint (default port 8100) implementing the WebDriver protocol. Sources live in `WebDriverAgentLib/`, `WebDriverAgentRunner/`, and `WebDriverAgentTests/`.
2. **A Node.js/TypeScript module** — the npm package consumed by Appium's XCUITest driver. It builds, installs, launches, and proxies to the Objective-C agent via `xcodebuild`/`appium-ios-device`. Sources live in `index.ts` and `lib/`.

Objective-C builds and Xcode-based tests require macOS with Xcode; only the Node.js side can be built and tested on other platforms.

## Commands (Node.js side)

```bash
npm install               # install dependencies
npm run build             # compile TypeScript (tsc -b) into build/
npm run dev               # build in watch mode
npm run lint              # eslint . (config: eslint.config.mjs)
npm run lint:fix
npm run format            # prettier -w ./lib ./test
npm run format:check      # CI runs this; keep code prettier-clean
npm test                  # mocha unit tests: test/unit/**/*-specs.ts
npm run e2e-test          # mocha functional tests (needs macOS + simulators)
```

Run a single unit test file (mocha loads `ts-node/register` via `.mocharc.js`, so no build step is needed):

```bash
npx mocha --exit --timeout 1m ./test/unit/utils-specs.ts
# narrow further with mocha's grep:
npx mocha --exit --timeout 1m ./test/unit/utils-specs.ts -g "pattern"
```

Bundling the prebuilt agent apps (macOS only):

```bash
npm run bundle            # builds both iOS and tvOS simulator zips
npm run bundle:ios        # TARGET=runner SDK=sim
npm run bundle:tv         # TARGET=tv_runner SDK=tv_sim
```

## Commands (Xcode side, macOS only)

Open `WebDriverAgent.xcodeproj` and run the `WebDriverAgentRunner` test scheme, or use Fastlane the way CI does (see `Fastlane/Fastfile` and `.github/workflows/wda-tests.yml`):

```bash
SCHEME=WebDriverAgentLib SDK=iphonesimulator DEVICE="iPhone 17" fastlane test   # ObjC unit tests
SCHEME=IntegrationTests_1 SDK=iphonesimulator DEVICE="iPhone 17" fastlane test # integration tests (schemes _1.._3)
```

`Scripts/build.sh` is the low-level build driver; it maps `TARGET` (`lib`, `runner`, `tv_lib`, `tv_runner`) and `SDK`/`DEST` env vars onto `xcodebuild` invocations with code signing disabled. `Scripts/build-webdriveragent.mjs` wraps it to produce the versioned `WebDriverAgentRunner-Runner-*.zip` bundles.

Shared schemes: `WebDriverAgentRunner`, `WebDriverAgentRunner_tvOS`, `WebDriverAgentLib`, `WebDriverAgentLib_tvOS`, `IntegrationApp`, `IntegrationTests_1`–`_3` (integration tests are split into three schemes to parallelize CI).

## Architecture

### Objective-C server (`WebDriverAgentLib/`)

- **`Routing/`** — the HTTP/command dispatch core. `FBWebServer` starts the vendored RoutingHTTPServer and discovers command handlers *at runtime by reflection*: every class conforming to the `FBCommandHandler` protocol is collected (`collectCommandHandlerClasses`) and its `+ (NSArray *)routes` method registers `FBRoute` entries. To add a new endpoint, add a route to the appropriate class in `Commands/` (or create a new class conforming to `FBCommandHandler`) — no central route table exists. `FBSession` holds per-session state; `FBElementCache` maps element UUIDs to `XCUIElement` instances.
- **`Commands/`** — endpoint implementations grouped by domain (`FBElementCommands`, `FBSessionCommands`, `FBFindElementCommands`, `FBScreenshotCommands`, etc.). Handlers receive an `FBRouteRequest` and return an `FBResponsePayload`.
- **`Categories/`** — the bulk of the automation logic lives in categories on Apple's XCUI classes (`XCUIElement+FBTyping`, `XCUIElement+FBFind`, `XCUIApplication+FBHelpers`, `XCUIDevice+FBRotation`, …). Behavior-level changes usually happen here, with `Commands/` acting as thin HTTP glue.
- **`Utilities/`** — cross-cutting helpers: `FBConfiguration` (global settings, many driven by session capabilities/settings API), `FBScreenshot`, `FBMjpegServer` (MJPEG frame streaming on a separate port), `FBXPath`, keyboard/alert monitors, etc.
- **`Vendor/`** — vendored CocoaHTTPServer and RoutingHTTPServer sources (upstream is unmaintained); avoid nontrivial edits here.
- **`PrivateHeaders/`** — dumped private headers for XCTest and other Apple frameworks. This is how WDA calls non-public XCTest API; these files mirror Apple's interfaces and are updated when new Xcode/iOS versions change them.
- `WebDriverAgentRunner/` is the shell UI-test target (`UITestingUITests.m`) that hosts the server: "running WDA" means running this XCTest target, which starts `FBWebServer` and blocks forever.

### Node.js module (`lib/`)

- `webdriveragent.ts` — the `WebDriverAgent` class, the package's main export. Orchestrates the agent lifecycle: decides between building via `xcodebuild`, using a prebuilt/preinstalled agent (`usePrebuiltWDA`, `usePreinstalledWDA`, `webDriverAgentUrl`), launches it (via `xcodebuild` or `appium-ios-device`'s `Xctest` for real devices), waits for the server to respond, and exposes proxies.
- `xcodebuild.ts` — wraps long-running `xcodebuild test` subprocess management, xctestrun file handling, and log parsing.
- `no-session-proxy.ts` / JWProxy from `@appium/base-driver` — HTTP proxying to the agent outside/inside a WebDriver session.
- `check-dependencies.ts` — `bundleWDASim` helper to build the sim bundle on demand.
- `constants.ts` — canonical bundle IDs, scheme name, ports, paths. The default runner bundle ID is `com.facebook.WebDriverAgentRunner` with the `.xctrunner` suffix for the test bundle.
- `types.ts` — `WebDriverAgentArgs` capability-ish options accepted by the class.

Public API surface is defined in `index.ts`; keep exports flowing through it.

## Conventions

- **PR titles must follow Conventional Commits** (angular preset) — CI enforces this (`.github/workflows/pr-title.yml`). Releases are automated with semantic-release, so `fix:`/`feat:`/`feat!:` prefixes determine version bumps.
- The npm package version and the Xcode agent version are kept in sync: `npm run sync-wda-version` (run automatically by `npm version`) writes the package version into `WebDriverAgentLib/Info.plist`. Don't hand-edit the version in that plist.
- TypeScript: prettier-formatted (100 char width, single quotes, no bracket spacing — see `package.json`), linted with `@appium/eslint-config-appium-ts`. `tsconfig.json` has `strict: false` (with a TODO to enable).
- Objective-C: 2-space indentation, ~80 character lines (per `CONTRIBUTING.md`); follow the existing `FB` class prefix and category-on-XCUI-class patterns.
- CI: `unit-test.yml` runs lint + `format:check` + Node unit tests on every push/PR; `wda-tests.yml` runs macOS matrix builds, static analysis, ObjC unit tests, and the three integration-test schemes across min/max supported Xcode versions.
