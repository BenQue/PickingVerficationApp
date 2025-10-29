import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/line_stock/presentation/widgets/barcode_input_field.dart';

void main() {
  group('BarcodeInputField', () {
    testWidgets('should display label and hint', (tester) async {
      // Arrange
      const label = 'Scan Barcode';
      const hint = 'Scan or enter barcode';
      String? submittedValue;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeInputField(
              label: label,
              hint: hint,
              onSubmit: (value) => submittedValue = value,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(label), findsOneWidget);
      expect(find.text(hint), findsOneWidget);
    });

    testWidgets('should have default prefix icon', (tester) async {
      // Arrange
      String? submittedValue;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeInputField(
              label: 'Barcode',
              hint: 'Scan',
              onSubmit: (value) => submittedValue = value,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    });

    testWidgets('should display custom prefix icon when provided',
        (tester) async {
      // Arrange
      String? submittedValue;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeInputField(
              label: 'Barcode',
              hint: 'Scan',
              prefixIcon: Icons.camera_alt,
              onSubmit: (value) => submittedValue = value,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.camera_alt), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner), findsNothing);
    });

    testWidgets('should autofocus by default', (tester) async {
      // Arrange
      String? submittedValue;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeInputField(
              label: 'Barcode',
              hint: 'Scan',
              onSubmit: (value) => submittedValue = value,
            ),
          ),
        ),
      );

      // Assert
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.autofocus, true);
    });

    testWidgets('should not autofocus when disabled', (tester) async {
      // Arrange
      String? submittedValue;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeInputField(
              label: 'Barcode',
              hint: 'Scan',
              autofocus: false,
              onSubmit: (value) => submittedValue = value,
            ),
          ),
        ),
      );

      // Assert
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.autofocus, false);
    });

    testWidgets('should call onSubmit when text is entered and debounced',
        (tester) async {
      // Arrange
      String? submittedValue;
      const testBarcode = 'TEST123456';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeInputField(
              label: 'Barcode',
              hint: 'Scan',
              onSubmit: (value) => submittedValue = value,
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), testBarcode);

      // Wait for debounce (100ms) + extra pump to execute timer callback
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(); // Execute the timer callback
      
      // Wait for processing delay (200ms) to complete
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(); // Execute processing reset timer

      // Assert
      expect(submittedValue, testBarcode);
    });

    testWidgets('should clear field after successful submission',
        (tester) async {
      // Arrange
      String? submittedValue;
      const testBarcode = 'TEST123456';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeInputField(
              label: 'Barcode',
              hint: 'Scan',
              onSubmit: (value) => submittedValue = value,
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), testBarcode);

      // Wait for debounce (100ms) + execute callback
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(); // Execute debounce timer callback
      
      // Wait for processing delay (200ms) to complete
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(); // Execute processing reset timer

      // Assert - Field should be cleared immediately after onSubmit
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, isEmpty);
    });

    testWidgets('should trim whitespace before submission', (tester) async {
      // Arrange
      String? submittedValue;
      const testBarcode = '  TEST123456  ';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeInputField(
              label: 'Barcode',
              hint: 'Scan',
              onSubmit: (value) => submittedValue = value,
            ),
          ),
        ),
      );

      // Enter text with spaces
      await tester.enterText(find.byType(TextField), testBarcode);

      // Wait for debounce + execute callback
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(); // Execute timer callback
      
      // Wait for processing delay (200ms) to complete
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(); // Execute processing reset timer

      // Assert - Whitespace trimmed
      expect(submittedValue, 'TEST123456');
    });

    testWidgets('should not submit empty text', (tester) async {
      // Arrange
      int submitCount = 0;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeInputField(
              label: 'Barcode',
              hint: 'Scan',
              onSubmit: (_) => submitCount++,
            ),
          ),
        ),
      );

      // Enter empty text
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pump(); // Rebuild after text entry

      // Wait for debounce + execute callback
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(); // Execute timer callback (should not trigger due to empty text)
      
      // Even though onSubmit wasn't called, wait for any potential processing timer
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();

      // Assert - onSubmit not called
      expect(submitCount, 0);
    });

    testWidgets('should show clear button when text is entered',
        (tester) async {
      // Arrange
      String? submittedValue;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeInputField(
              label: 'Barcode',
              hint: 'Scan',
              autofocus: false, // Disable autofocus for this test
              onSubmit: (value) => submittedValue = value,
            ),
          ),
        ),
      );

      // Assert - No clear button initially
      expect(find.byIcon(Icons.clear), findsNothing);

      // Enter text
      await tester.enterText(find.byType(TextField), 'TEST');
      await tester.pump(); // Rebuild to show clear button

      // Assert - Clear button appears
      expect(find.byIcon(Icons.clear), findsOneWidget);
      
      // Clean up: wait for debounce and processing timers to complete before test ends
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(); // Execute debounce timer callback
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(); // Execute processing reset timer
    });

    testWidgets('should clear text when clear button is tapped',
        (tester) async {
      // Arrange
      String? submittedValue;
      final controller = TextEditingController();

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeInputField(
              label: 'Barcode',
              hint: 'Scan',
              controller: controller,
              autofocus: false,
              onSubmit: (value) => submittedValue = value,
            ),
          ),
        ),
      );

      // Enter text
      await tester.enterText(find.byType(TextField), 'TEST123');
      await tester.pump(); // Rebuild to show clear button

      // Tap clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump(); // Rebuild after clear

      // Assert - Text cleared
      expect(controller.text, isEmpty);
      
      // Clean up: wait for timers to complete before test ends
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(); // Execute any pending debounce timer
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(); // Execute any pending processing timer
    });

    testWidgets('should be disabled when enabled is false', (tester) async {
      // Arrange
      String? submittedValue;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeInputField(
              label: 'Barcode',
              hint: 'Scan',
              enabled: false,
              onSubmit: (value) => submittedValue = value,
            ),
          ),
        ),
      );

      // Assert
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.enabled, false);
    });

    testWidgets('should accept external controller', (tester) async {
      // Arrange
      String? submittedValue;
      final controller = TextEditingController(text: 'INITIAL');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeInputField(
              label: 'Barcode',
              hint: 'Scan',
              controller: controller,
              onSubmit: (value) => submittedValue = value,
            ),
          ),
        ),
      );

      // Assert - Initial value from controller
      expect(find.text('INITIAL'), findsOneWidget);
      expect(controller.text, 'INITIAL');
    });

    testWidgets('should debounce rapid input changes', (tester) async {
      // Arrange
      int submitCount = 0;
      String? lastSubmittedValue;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeInputField(
              label: 'Barcode',
              hint: 'Scan',
              onSubmit: (value) {
                submitCount++;
                lastSubmittedValue = value;
              },
            ),
          ),
        ),
      );

      // Rapidly enter text
      await tester.enterText(find.byType(TextField), 'T');
      await tester.pump(); // Rebuild
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byType(TextField), 'TE');
      await tester.pump(); // Rebuild
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byType(TextField), 'TEST');
      await tester.pump(); // Rebuild

      // Wait for debounce
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(); // Execute timer callback
      
      // Wait for processing delay to complete
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(); // Execute processing reset timer

      // Assert - Only submitted once with final value
      expect(submitCount, 1);
      expect(lastSubmittedValue, 'TEST');
    });

    testWidgets('should have correct text styling', (tester) async {
      // Arrange
      String? submittedValue;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeInputField(
              label: 'Barcode',
              hint: 'Scan',
              onSubmit: (value) => submittedValue = value,
            ),
          ),
        ),
      );

      // Assert
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.style?.fontSize, 22);
      expect(textField.style?.fontWeight, FontWeight.w500);
    });

    testWidgets('should call onSubmit when Enter key is pressed',
        (tester) async {
      // Arrange
      String? submittedValue;
      const testBarcode = 'TEST123456';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BarcodeInputField(
              label: 'Barcode',
              hint: 'Scan',
              onSubmit: (value) => submittedValue = value,
            ),
          ),
        ),
      );

      // Enter text and submit
      await tester.enterText(find.byType(TextField), testBarcode);
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // Assert
      expect(submittedValue, testBarcode);
    });
  });
}
