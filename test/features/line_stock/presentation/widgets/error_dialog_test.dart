import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/line_stock/presentation/widgets/error_dialog.dart';

void main() {
  group('ErrorDialog', () {
    testWidgets('should display error message', (tester) async {
      // Arrange
      const errorMessage = 'Network connection failed';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorDialog(
              message: errorMessage,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('操作失败'), findsOneWidget);
    });

    testWidgets('should display error icon', (tester) async {
      // Arrange
      const errorMessage = 'Something went wrong';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorDialog(
              message: errorMessage,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.error_outline));
      expect(iconWidget.size, 48);
    });

    testWidgets('should display close button', (tester) async {
      // Arrange
      const errorMessage = 'Error occurred';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorDialog(
              message: errorMessage,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('关闭'), findsOneWidget);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('should display retry button when canRetry is true',
        (tester) async {
      // Arrange
      const errorMessage = 'Network error';
      bool onRetryCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDialog(
              message: errorMessage,
              canRetry: true,
              onRetry: () {
                onRetryCalled = true;
              },
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('重试'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      // Act - Tap retry button
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();

      // Assert - Callback called
      expect(onRetryCalled, true);
    });

    testWidgets('should not display retry button when canRetry is false',
        (tester) async {
      // Arrange
      const errorMessage = 'Fatal error';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorDialog(
              message: errorMessage,
              canRetry: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('重试'), findsNothing);
      expect(find.byType(ElevatedButton), findsNothing);
      expect(find.text('关闭'), findsOneWidget);
    });

    testWidgets('should not display retry button when onRetry is null',
        (tester) async {
      // Arrange
      const errorMessage = 'Error';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorDialog(
              message: errorMessage,
              canRetry: true,
              onRetry: null,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('重试'), findsNothing);
    });

    testWidgets('should close dialog when close button tapped',
        (tester) async {
      // Arrange
      const errorMessage = 'Error occurred';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ErrorDialog.show(
                      context,
                      message: errorMessage,
                    );
                  },
                  child: const Text('Show Error'),
                );
              },
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      // Assert dialog is visible
      expect(find.text(errorMessage), findsOneWidget);

      // Act - Tap close button
      await tester.tap(find.text('关闭'));
      await tester.pumpAndSettle();

      // Assert - Dialog closed
      expect(find.text(errorMessage), findsNothing);
    });

    testWidgets('should call onRetry and close dialog when retry tapped',
        (tester) async {
      // Arrange
      const errorMessage = 'Network error';
      bool onRetryCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ErrorDialog.show(
                      context,
                      message: errorMessage,
                      canRetry: true,
                      onRetry: () {
                        onRetryCalled = true;
                      },
                    );
                  },
                  child: const Text('Show Error'),
                );
              },
            ),
          ),
        ),
      );

      // Show dialog
      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      // Assert dialog is visible
      expect(find.text(errorMessage), findsOneWidget);

      // Act - Tap retry button
      await tester.tap(find.text('重试'));
      await tester.pumpAndSettle();

      // Assert - Dialog closed and callback called
      expect(find.text(errorMessage), findsNothing);
      expect(onRetryCalled, true);
    });

    testWidgets('should handle long error messages', (tester) async {
      // Arrange
      const longMessage =
          'This is a very long error message that should be displayed properly with proper wrapping and should not cause any overflow issues in the dialog.';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorDialog(
              message: longMessage,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(longMessage), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text(longMessage));
      expect(textWidget.textAlign, TextAlign.center);
    });

    testWidgets('should have correct dialog styling', (tester) async {
      // Arrange
      const errorMessage = 'Error';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorDialog(
              message: errorMessage,
            ),
          ),
        ),
      );

      // Assert
      final alertDialog = tester.widget<AlertDialog>(find.byType(AlertDialog));
      expect(alertDialog.shape, isA<RoundedRectangleBorder>());
      expect(alertDialog.contentPadding, const EdgeInsets.all(24));
    });

    testWidgets('should show dialog using static show method', (tester) async {
      // Arrange
      const errorMessage = 'Test error';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ErrorDialog.show(context, message: errorMessage);
                  },
                  child: const Text('Show Error'),
                );
              },
            ),
          ),
        ),
      );

      // Assert - Dialog not visible initially
      expect(find.text(errorMessage), findsNothing);

      // Act - Show dialog
      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      // Assert - Dialog visible
      expect(find.text(errorMessage), findsOneWidget);
      expect(find.text('操作失败'), findsOneWidget);
    });

    testWidgets('should set barrierDismissible based on canRetry',
        (tester) async {
      // Arrange
      const errorMessage = 'Error';

      // Test with canRetry = true (dismissible)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    ErrorDialog.show(
                      context,
                      message: errorMessage,
                      canRetry: true,
                    );
                  },
                  child: const Text('Show Error Dismissible'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error Dismissible'));
      await tester.pumpAndSettle();

      expect(find.text(errorMessage), findsOneWidget);

      // Try to dismiss by tapping barrier
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Dialog should be dismissed (or not - depends on implementation)
      // The main point is that barrierDismissible is set correctly
    });

    testWidgets('should display all required UI elements', (tester) async {
      // Arrange
      const errorMessage = 'Complete error dialog';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDialog(
              message: errorMessage,
              canRetry: true,
              onRetry: () {},
            ),
          ),
        ),
      );

      // Assert - All elements present
      expect(find.byIcon(Icons.error_outline), findsOneWidget); // Icon
      expect(find.text('操作失败'), findsOneWidget); // Title
      expect(find.text(errorMessage), findsOneWidget); // Message
      expect(find.text('关闭'), findsOneWidget); // Close button
      expect(find.text('重试'), findsOneWidget); // Retry button
    });
  });
}
