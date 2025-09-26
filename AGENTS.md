# Repository Guidelines

## Project Structure & Module Organization
- `lib/` holds production code; `core/` centralizes themes, routing, and the shared Dio client, while `features/` are split into data/domain/presentation layers for modules such as `picking_verification`, `order_verification`, and `task_board`.
- `lib/main.dart` wires the full workflow, while `lib/main_simple.dart` starts the simplified flow documented in `README_SIMPLE.md`.
- Tests live in `test/` mirroring `lib/`, with integration suites in `test/integration/` and widget specs beside each feature folder.
- Assets reside in `assets/images/`; remember to register new media in `pubspec.yaml`.
- Use `scripts/` for automation (`run_simple.sh`, `test_mock_data.sh`) and `docs/` for supporting specs and API notes.

## Build, Test, and Development Commands
- `flutter pub get` syncs dependencies after editing `pubspec.yaml`.
- `flutter run` launches the full app; add `-t lib/main_simple.dart` for the simplified build or run `./scripts/run_simple.sh`.
- `flutter build apk --release -t lib/main_simple.dart` produces the industrial PDA release in `build/app/outputs/flutter-apk/`.
- `flutter test` runs unit and widget suites; append `--coverage` to refresh `coverage/lcov.info`.
- `flutter analyze` and `dart format .` keep lints clean; run `./scripts/test_mock_data.sh` when validating mock workflows end-to-end.

## Coding Style & Naming Conventions
- Follow Flutter’s default two-space indentation and the lint set in `analysis_options.yaml` (`package:flutter_lints/flutter.yaml`).
- Name files with `snake_case.dart`; reserve `*_bloc.dart`, `*_screen.dart`, and `*_widget.dart` for their respective roles.
- Classes and enums use `PascalCase`; methods, variables, and BLoC events/states stay `camelCase`.
- Keep presentation logic in widgets, business logic in BLoCs, and networking in repositories/datasources.
- Run `dart format .` before commits; avoid disabling lints unless the rationale is documented.

## Testing Guidelines
- Use `flutter_test` with `bloc_test`, `mocktail`, or `mockito` to isolate dependencies.
- Co-locate unit tests under `test/<feature>/` with filenames ending in `*_test.dart`.
- Add widget tests for UI contracts and integration tests for multi-step flows in `test/integration/`.
- Maintain or improve coverage when touching a module; capture regressions with scenario-focused tests.
- Document manual scenarios (e.g., mock order IDs) in PR descriptions when automation is not feasible.

## Commit & Pull Request Guidelines
- Commit messages follow an imperative mood with Conventional Commit prefixes (`feat`, `fix`, `chore`, `docs`), e.g., `feat(picking): support partial scans`.
- Keep commits focused; include schema changes and generated files together with the source that produced them.
- PRs should summarize the change, link tracking issues, attach relevant screenshots (mobile layouts) or test logs, and note any scripts run.
- Ensure `flutter test`, `flutter analyze`, and required build commands succeed locally before requesting review.
- Call out configuration updates (API base URLs, credentials) so deployment checkpoints stay aligned.

## Security & Configuration Tips
- API endpoints and credentials live in data sources such as `lib/features/picking_verification/data/datasources/`; do not hardcode secrets beyond documented defaults.
- Use environment-specific branches or configs when altering `lib/core/api/dio_client.dart` base URLs.
- Re-run `flutter pub outdated` periodically to surface dependency patches, but validate PDA bundles before upgrading runtime libraries.
