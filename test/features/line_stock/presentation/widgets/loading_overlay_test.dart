import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/line_stock/presentation/widgets/loading_overlay.dart';

void main() {
  group('LoadingOverlay', () {
    testWidgets('should display child widget when isLoading is false',
        (tester) async {
      // Arrange
      const childWidget = Text('Child Content');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              isLoading: false,
              child: childWidget,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Child Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should display loading indicator when isLoading is true',
        (tester) async {
      // Arrange
      const childWidget = Text('Child Content');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              isLoading: true,
              child: childWidget,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('Child Content'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('should display message when provided', (tester) async {
      // Arrange
      const childWidget = Text('Child Content');
      const loadingMessage = 'Loading data...';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              isLoading: true,
              message: loadingMessage,
              child: childWidget,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(loadingMessage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('should not display message when not provided',
        (tester) async {
      // Arrange
      const childWidget = Text('Child Content');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              isLoading: true,
              child: childWidget,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // Message text should not be found (only loading indicator)
      final textFinder = find.descendant(
        of: find.byType(Card),
        matching: find.byType(Text),
      );
      expect(textFinder, findsNothing);
    });

    testWidgets('should have semi-transparent black background when loading',
        (tester) async {
      // Arrange
      const childWidget = Text('Child Content');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              isLoading: true,
              child: childWidget,
            ),
          ),
        ),
      );

      // Assert
      final containerFinder = find.descendant(
        of: find.byType(Stack),
        matching: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.color == Colors.black.withOpacity(0.5),
        ),
      );
      expect(containerFinder, findsOneWidget);
    });

    testWidgets('should display child and overlay in Stack', (tester) async {
      // Arrange
      const childWidget = Text('Child Content');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              isLoading: true,
              child: childWidget,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Stack), findsOneWidget);
      final stackWidget = tester.widget<Stack>(find.byType(Stack));
      expect(stackWidget.children.length, 2); // child + overlay
    });

    testWidgets('should toggle loading state correctly', (tester) async {
      // Arrange
      const childWidget = Text('Child Content');
      bool isLoading = true;

      // Act - Initial state (loading)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return LoadingOverlay(
                  isLoading: isLoading,
                  child: childWidget,
                );
              },
            ),
          ),
        ),
      );

      // Assert - Loading indicator visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Act - Change state to not loading
      isLoading = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              isLoading: isLoading,
              child: childWidget,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert - Loading indicator not visible
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('should handle long message text correctly', (tester) async {
      // Arrange
      const childWidget = Text('Child Content');
      const longMessage =
          'This is a very long loading message that should wrap properly and be centered in the loading card without causing overflow issues.';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              isLoading: true,
              message: longMessage,
              child: childWidget,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(longMessage), findsOneWidget);
      final textWidget = tester.widget<Text>(find.text(longMessage));
      expect(textWidget.textAlign, TextAlign.center);
    });

    testWidgets('should center the loading card', (tester) async {
      // Arrange
      const childWidget = Text('Child Content');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              isLoading: true,
              child: childWidget,
            ),
          ),
        ),
      );

      // Assert
      final centerFinder = find.descendant(
        of: find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.color == Colors.black.withOpacity(0.5),
        ),
        matching: find.byType(Center),
      );
      expect(centerFinder, findsOneWidget);
    });

    testWidgets('should have correct card styling', (tester) async {
      // Arrange
      const childWidget = Text('Child Content');

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: LoadingOverlay(
              isLoading: true,
              child: childWidget,
            ),
          ),
        ),
      );

      // Assert
      final cardWidget = tester.widget<Card>(find.byType(Card));
      expect(cardWidget.elevation, 8);
      expect(cardWidget.shape, isA<RoundedRectangleBorder>());
    });
  });
}
