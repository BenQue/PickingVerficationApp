import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/line_stock/presentation/widgets/success_dialog.dart';

void main() {
  group('SuccessDialog', () {
    testWidgets('should display success message', (tester) async {
      // Arrange
      const successMessage = 'Operation completed successfully';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SuccessDialog(
              message: successMessage,
            ),
          ),
        ),
      );
      await tester.pump(); // Pump for animation

      // Assert
      expect(find.text(successMessage), findsOneWidget);
      expect(find.text('操作成功'), findsOneWidget);
    });

    testWidgets('should display success icon', (tester) async {
      // Arrange
      const successMessage = 'Success';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SuccessDialog(
              message: successMessage,
            ),
          ),
        ),
      );
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      final iconWidget =
          tester.widget<Icon>(find.byIcon(Icons.check_circle));
      expect(iconWidget.size, 48);
    });

    testWidgets('should display close button', (tester) async {
      // Arrange
      const successMessage = 'Success';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SuccessDialog(
              message: successMessage,
            ),
          ),
        ),
      );
      await tester.pump();

      // Assert
      expect(find.text('关闭'), findsOneWidget);
      expect(find.byType(TextButton), findsOneWidget);
    });

    testWidgets('should display statistics when provided', (tester) async {
      // Arrange
      const successMessage = 'Transfer completed';
      const statistics = {
        '目标库位': 'A01-01-01',
        '转移数量': '5 件',
      };

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SuccessDialog(
              message: successMessage,
              statistics: statistics,
            ),
          ),
        ),
      );
      await tester.pump();

      // Assert
      expect(find.text('目标库位'), findsOneWidget);
      expect(find.text('A01-01-01'), findsOneWidget);
      expect(find.text('转移数量'), findsOneWidget);
      expect(find.text('5 件'), findsOneWidget);
    });

    testWidgets('should not display statistics section when not provided',
        (tester) async {
      // Arrange
      const successMessage = 'Success';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SuccessDialog(
              message: successMessage,
            ),
          ),
        ),
      );
      await tester.pump();

      // Assert - Statistics container should not exist
      final containerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == Colors.grey.shade100,
      );
      expect(containerFinder, findsNothing);
    });

    testWidgets('should close dialog when close button tapped',
        (tester) async {
      // Arrange
      const successMessage = 'Success';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    SuccessDialog.show(
                      context,
                      message: successMessage,
                      autoDismissDuration: const Duration(seconds: 10),
                    );
                  },
                  child: const Text('Show Success'),
                );
              },
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Success'));
      await tester.pumpAndSettle();

      // Assert dialog is visible
      expect(find.text(successMessage), findsOneWidget);

      // Act - Tap close button
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();

      // Assert - Dialog closed
      expect(find.text(successMessage), findsNothing);
    });

    testWidgets('should call onDismissed when close button tapped',
        (tester) async {
      // Arrange
      const successMessage = 'Success';
      bool onDismissedCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    SuccessDialog.show(
                      context,
                      message: successMessage,
                      autoDismissDuration: const Duration(seconds: 10),
                      onDismissed: () {
                        onDismissedCalled = true;
                      },
                    );
                  },
                  child: const Text('Show Success'),
                );
              },
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Success'));
      await tester.pumpAndSettle();

      // Act - Tap close button
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();

      // Assert - Callback called
      expect(onDismissedCalled, true);
    });

    testWidgets('should auto-dismiss after duration', (tester) async {
      // Arrange
      const successMessage = 'Success';
      const autoDismissDuration = Duration(milliseconds: 100);

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    SuccessDialog.show(
                      context,
                      message: successMessage,
                      autoDismissDuration: autoDismissDuration,
                    );
                  },
                  child: const Text('Show Success'),
                );
              },
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Success'));
      await tester.pump(); // Start showing dialog
      await tester.pump(); // Complete dialog entrance animation
      
      // Assert dialog is visible before auto-dismiss
      expect(find.text(successMessage), findsOneWidget);
      expect(find.byType(SuccessDialog), findsOneWidget);

      // Act - Wait for auto-dismiss timer
      await tester.pump(autoDismissDuration);
      await tester.pump(); // Execute timer callback to close dialog
      await tester.pumpAndSettle(); // Wait for dialog dismiss animation

      // Assert - Dialog has been auto-dismissed
      expect(find.text(successMessage), findsNothing);
      expect(find.byType(SuccessDialog), findsNothing);
    });

    testWidgets('should call onDismissed when auto-dismissed',
        (tester) async {
      // Arrange
      const successMessage = 'Success';
      const autoDismissDuration = Duration(milliseconds: 100);
      bool onDismissedCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    SuccessDialog.show(
                      context,
                      message: successMessage,
                      autoDismissDuration: autoDismissDuration,
                      onDismissed: () {
                        onDismissedCalled = true;
                      },
                    );
                  },
                  child: const Text('Show Success'),
                );
              },
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Success'));
      await tester.pumpAndSettle();

      // Wait for auto-dismiss
      await tester.pump(autoDismissDuration);
      await tester.pumpAndSettle();

      // Assert - Callback called
      expect(onDismissedCalled, true);
    });

    testWidgets('should cancel timer when manually closed', (tester) async {
      // Arrange
      const successMessage = 'Success';
      int dismissCount = 0;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    SuccessDialog.show(
                      context,
                      message: successMessage,
                      autoDismissDuration: const Duration(seconds: 10),
                      onDismissed: () {
                        dismissCount++;
                      },
                    );
                  },
                  child: const Text('Show Success'),
                );
              },
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Success'));
      await tester.pumpAndSettle();

      // Manually close
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();

      // Assert - Only called once (not by timer)
      expect(dismissCount, 1);

      // Wait for what would have been auto-dismiss time
      await tester.pump(const Duration(seconds: 10));
      await tester.pumpAndSettle();

      // Assert - Still only called once
      expect(dismissCount, 1);
    });

    testWidgets('should handle long success messages', (tester) async {
      // Arrange
      const longMessage =
          'This is a very long success message that should be displayed properly with proper wrapping and centered text alignment.';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SuccessDialog(
              message: longMessage,
            ),
          ),
        ),
      );
      await tester.pump();

      // Assert
      expect(find.text(longMessage), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text(longMessage));
      expect(textWidget.textAlign, TextAlign.center);
    });

    testWidgets('should have correct dialog styling', (tester) async {
      // Arrange
      const successMessage = 'Success';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SuccessDialog(
              message: successMessage,
            ),
          ),
        ),
      );
      await tester.pump();

      // Assert
      final alertDialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(alertDialog.shape, isA<RoundedRectangleBorder>());
      expect(alertDialog.contentPadding, const EdgeInsets.all(24));
    });

    testWidgets('should show icon scale animation', (tester) async {
      // Arrange
      const successMessage = 'Success';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SuccessDialog(
              message: successMessage,
            ),
          ),
        ),
      );

      // Assert - Animation builder exists
      expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);

      // Pump animation
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump(const Duration(milliseconds: 250));

      // Assert - Icon still visible after animation
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should display all required UI elements', (tester) async {
      // Arrange
      const successMessage = 'Complete success dialog';
      const statistics = {'转移数量': '3 件'};

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SuccessDialog(
              message: successMessage,
              statistics: statistics,
            ),
          ),
        ),
      );
      await tester.pump();

      // Assert - All elements present
      expect(find.byIcon(Icons.check_circle), findsOneWidget); // Icon
      expect(find.text('操作成功'), findsOneWidget); // Title
      expect(find.text(successMessage), findsOneWidget); // Message
      expect(find.text('转移数量'), findsOneWidget); // Statistics
      expect(find.text('关闭'), findsOneWidget); // Close button
    });

    testWidgets('should handle empty statistics map', (tester) async {
      // Arrange
      const successMessage = 'Success';
      const emptyStatistics = <String, String>{};

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SuccessDialog(
              message: successMessage,
              statistics: emptyStatistics,
            ),
          ),
        ),
      );
      await tester.pump();

      // Assert - Statistics section should not be displayed
      final containerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == Colors.grey.shade100,
      );
      expect(containerFinder, findsNothing);
    });
  });
}
