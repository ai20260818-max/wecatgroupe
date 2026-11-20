# WeChat Group Manager V1.2

macOS SwiftUI prototype for managing WeChat group exit lists. **This version does not automatically discover groups or leave groups.** It includes a read-only Accessibility inspection, manual records, protection flags, previews, and CSV export.

Build on macOS using `bash scripts/build-macos.sh`. The GitHub Actions workflow packages an unsigned, unnotarized DMG for testing. It is not verified against WeChat 4.2.

Do not use with real groups until identity verification and exit automation have been implemented and tested.

## Build verification

Builds require Apple Silicon or an SDK supporting the arm64 target. The app targets macOS 13+. `swiftc -parse-as-library` is required for the SwiftUI `@main` entry point. The script cleans its staging directories before each build and writes a SHA-256 checksum beside the DMG. Build output is ignored by Git.

The DMG contains the application, an Applications shortcut, and a Chinese prototype notice. It uses an ad-hoc signature and has not been notarized by Apple. Successful compilation or launch does not mean WeChat 4.2 scanning or group exit has been implemented.

Actions run #6 failed before compilation: GitHub reported that a hosted runner could not acquire the job after multiple attempts, with macOS arm64 capacity constraints. Repeatedly starting jobs does not solve that capacity issue. The same source can be built locally with the command above.
