import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/main.dart';

void main() {
  group('PickingVerificationApp Tests', () {
    testWidgets('App should build without errors', (WidgetTester tester) async {
      // Store original ErrorWidget.builder
      final originalErrorWidgetBuilder = ErrorWidget.builder;
      
      // Build the app
      await tester.pumpWidget(const PickingVerificationApp());
      
      // Wait for any async operations to complete
      await tester.pumpAndSettle();
      
      // Verify that the app builds without throwing exceptions
      expect(tester.takeException(), isNull);
      
      // Restore original ErrorWidget.builder to avoid test framework warnings
      ErrorWidget.builder = originalErrorWidgetBuilder;
    });
  });

  group('AppExceptionHandler Tests', () {
    test('should initialize without errors', () {
      // Test that the exception handler can be initialized
      expect(() => AppExceptionHandler.initialize(), returnsNormally);
    });
  });
}