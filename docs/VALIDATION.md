# Validation

Environment: Windows, existing Flutter 3.47.5 / Dart 3.13.4 SDK at `C:\Users\lazyg\develop\flutter`. Validation date: 25 October 2026.

Commands used for the release candidate:

```powershell
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --concurrency=1
flutter build web --no-web-resources-cdn --no-wasm-dry-run
```

The suite checks age-band isolation (including explicitly shared lessons), bounded journeys, disabled subjects, recent/review suggestions, quiz and retry scoring, mastery transitions, configured matching and drag/drop, tracing coverage, saved completion/profile isolation, corrupt persistence, malformed/unknown content, step resume, profile selection, large preschool cards, quiz choices, protected parent routes, adult gate and lifecycle relocking, and inaccessible lessons.

Results: **27 tests passed**, static analysis reports **no issues**, formatting passes, and the release web build succeeds. Additional regressions cover failed writes/retry, settings reload, missing-image fallback and relocking the dashboard underneath a closed settings route.

Release web compilation uses local renderer resources and the bundled Hindi font. The build may emit Flutter's generic tree-shaking notice about an absent optional Cupertino icon font; the app uses Material icons and has no Cupertino package dependency.

Android release packaging and physical-device checks have not been run. Automated widget tests verify behavior and basic rendering; they are not substitutes for device checks of touch, screen readers, font shaping, interruption handling or curriculum suitability.
