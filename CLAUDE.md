# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter-based industrial PDA application for warehouse picking verification and traceability. The app provides digitized workflows for three key processes: container verification, platform receiving, and line delivery confirmation.

**Core Features:**
- User authentication with role-based permissions
- Task board with assigned order lists
- Picking verification with material status tracking
- Order verification via QR scanning
- Container, platform, and line delivery workflows

## Development Commands

### Basic Flutter Commands
```bash
# Install dependencies
flutter pub get

# Run the app on connected device
flutter run

# Build for release
flutter build apk --release

# Run tests
flutter test

# Run specific test file
flutter test test/features/auth/presentation/bloc/auth_bloc_test.dart

# Run integration tests
flutter test test/integration/

# Generate code (for mocks and models)
flutter packages pub run build_runner build

# Clean and rebuild
flutter clean && flutter pub get
```

### Testing Commands
```bash
# Run all unit tests
flutter test

# Run tests with coverage
flutter test --coverage

# Run integration tests
flutter test test/integration/

# Run widget tests for specific feature
flutter test test/features/picking_verification/presentation/widgets/
```

### Analysis and Linting
```bash
# Analyze code for issues
flutter analyze

# Format code
dart format .

# Check for outdated dependencies
flutter pub outdated
```

### Utility Scripts
```bash
# Run simplified version (focused on container verification)
./scripts/run_simple.sh

# Test with mock data (includes test scenarios)
./scripts/test_mock_data.sh
```

## Architecture Overview

**Architecture Pattern:** Clean Architecture with feature-first organization
**State Management:** BLoC (Business Logic Component) pattern using flutter_bloc
**Navigation:** GoRouter for declarative routing with authentication guards
**API Integration:** Dio HTTP client with interceptors
**Storage:** Flutter Secure Storage for credentials

### Feature Structure
Each feature follows this structure:
```
features/{feature_name}/
├── data/
│   ├── datasources/     # Remote API calls
│   ├── models/          # Data transfer objects
│   └── repositories/    # Repository implementations
├── domain/
│   ├── entities/        # Business objects
│   ├── repositories/    # Repository interfaces
│   └── usecases/        # Business logic
└── presentation/
    ├── pages/           # Screen widgets
    ├── widgets/         # Feature-specific widgets
    └── bloc/            # BLoC state management
```

### Core Features
1. **auth/** - User authentication and permission management
2. **task_board/** - Personal task dashboard with role-based task filtering
3. **picking_verification/** - Main container verification workflow
4. **order_verification/** - QR code scanning and order validation
5. **platform_receiving/** - Platform material receiving confirmation
6. **line_delivery/** - Production line delivery confirmation

## Key Dependencies

**UI Framework:**
- `flutter: sdk` - Flutter framework
- `cupertino_icons: ^1.0.8` - iOS-style icons

**State Management:**
- `flutter_bloc: ^8.1.0` - BLoC pattern implementation
- `equatable: ^2.0.5` - Value equality for states/events

**Networking:**
- `dio: ^5.0.0` - HTTP client with interceptors

**Navigation:**
- `go_router: ^10.0.0` - Declarative routing

**Storage:**
- `flutter_secure_storage: ^9.0.0` - Secure credential storage

**Hardware Integration:**
- `mobile_scanner: ^5.0.0` - QR code scanning
- `permission_handler: ^11.0.0` - Device permissions

**Testing:**
- `flutter_test: sdk` - Flutter testing framework
- `bloc_test: ^9.1.0` - BLoC testing utilities
- `mockito: ^5.4.0` - Mock object generation
- `mocktail: ^1.0.0` - Alternative mocking framework
- `build_runner: ^2.4.0` - Code generation

## Development Guidelines

### BLoC Pattern Implementation
- Events represent user interactions or system triggers
- States represent UI state changes
- Business logic lives in BLoC classes, not widgets
- Use `bloc_test` for comprehensive BLoC testing

### API Integration
- All network calls go through `DioClient` with proper error handling
- Repository pattern abstracts data sources from business logic
- Use models for API DTOs, entities for domain objects

### Testing Strategy
- Unit tests for all BLoCs, repositories, and utilities
- Widget tests for complex UI components
- Integration tests for complete user workflows
- Mock external dependencies using `mockito`

### Code Organization
- Follow feature-first organization
- Keep widgets focused and reusable
- Use consistent naming: `*_screen.dart` for pages, `*_widget.dart` for reusable components
- Group related functionality in feature folders

### Industrial PDA Considerations
- UI designed for high contrast and large touch targets
- Portrait-only orientation
- Network resilience with proper error handling
- Secure storage for sensitive data

## Common Development Patterns

### Adding a New Feature
1. Create feature folder structure under `lib/features/`
2. Implement data layer (datasources, models, repositories)
3. Define domain layer (entities, repository interfaces)
4. Build presentation layer (pages, widgets, BLoC)
5. Add routes to `AppRouter`
6. Write comprehensive tests

### BLoC Testing Pattern
```dart
group('AuthBloc', () {
  late AuthBloc authBloc;
  late MockAuthRepository mockRepository;
  
  setUp(() {
    mockRepository = MockAuthRepository();
    authBloc = AuthBloc(authRepository: mockRepository);
  });
  
  blocTest<AuthBloc, AuthState>(
    'emits [AuthLoading, AuthSuccess] when login succeeds',
    build: () => authBloc,
    act: (bloc) => bloc.add(LoginRequested('user', 'pass')),
    expect: () => [AuthLoading(), AuthSuccess(user)],
  );
});
```

### Widget Testing Pattern
```dart
testWidgets('MaterialItemWidget displays status correctly', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MaterialItemWidget(
        material: mockMaterial,
        onStatusChange: (status) {},
      ),
    ),
  );
  
  expect(find.text(mockMaterial.materialCode), findsOneWidget);
  expect(find.byType(MaterialStatusIndicator), findsOneWidget);
});
```

## File Organization

**Core Files:**
- `lib/main.dart` - App entry point with global configuration
- `lib/core/config/app_router.dart` - Route definitions with guards
- `lib/core/theme/app_theme.dart` - Industrial UI theme
- `lib/core/api/dio_client.dart` - HTTP client configuration

**Test Structure:**
- `test/` mirrors `lib/` structure
- `test/integration/` for end-to-end workflow tests
- Use `.mocks.dart` suffix for generated mock files

**Assets:**
- `assets/images/` for app images and company branding
- High-contrast images suitable for industrial environments