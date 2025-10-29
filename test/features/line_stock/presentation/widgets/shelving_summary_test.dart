import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/line_stock/presentation/widgets/shelving_summary.dart';

void main() {
  group('ShelvingSummary', () {
    testWidgets('should display summary header', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShelvingSummary(
              targetLocation: null,
              cableCount: 0,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('转移摘要'), findsOneWidget);
    });

    testWidgets('should display "未设置" when no target location',
        (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShelvingSummary(
              targetLocation: null,
              cableCount: 0,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('目标库位'), findsOneWidget);
      expect(find.text('未设置'), findsOneWidget);
    });

    testWidgets('should display target location when provided',
        (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShelvingSummary(
              targetLocation: 'A01-01-01',
              cableCount: 0,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('目标库位'), findsOneWidget);
      expect(find.text('A01-01-01'), findsOneWidget);
      expect(find.text('未设置'), findsNothing);
    });

    testWidgets('should display "未添加" when no cables', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShelvingSummary(
              targetLocation: 'A01-01-01',
              cableCount: 0,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('电缆数量'), findsOneWidget);
      expect(find.text('未添加'), findsOneWidget);
    });

    testWidgets('should display cable count when > 0', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShelvingSummary(
              targetLocation: 'A01-01-01',
              cableCount: 5,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('电缆数量'), findsOneWidget);
      expect(find.text('5 条'), findsOneWidget);
      expect(find.text('未添加'), findsNothing);
    });

    testWidgets('should show warning when no target location set',
        (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShelvingSummary(
              targetLocation: null,
              cableCount: 3,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('请先设置目标库位'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('should show warning when no cables added', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShelvingSummary(
              targetLocation: 'A01-01-01',
              cableCount: 0,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('请添加至少一条电缆'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('should not show warning when ready', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShelvingSummary(
              targetLocation: 'A01-01-01',
              cableCount: 3,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('请先设置目标库位'), findsNothing);
      expect(find.text('请添加至少一条电缆'), findsNothing);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('should show check icon when ready', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShelvingSummary(
              targetLocation: 'A01-01-01',
              cableCount: 5,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    });

    testWidgets('should show info icon when not ready', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShelvingSummary(
              targetLocation: null,
              cableCount: 0,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
    });

    testWidgets('should display location icon', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShelvingSummary(
              targetLocation: 'A01-01-01',
              cableCount: 0,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });

    testWidgets('should display cable icon', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShelvingSummary(
              targetLocation: 'A01-01-01',
              cableCount: 3,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.cable), findsOneWidget);
    });

    testWidgets('should be wrapped in a Card', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShelvingSummary(
              targetLocation: 'A01-01-01',
              cableCount: 3,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('should handle empty target location string', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShelvingSummary(
              targetLocation: '',
              cableCount: 3,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('未设置'), findsOneWidget);
      expect(find.text('请先设置目标库位'), findsOneWidget);
    });

    testWidgets('should handle single cable', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShelvingSummary(
              targetLocation: 'A01-01-01',
              cableCount: 1,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('1 条'), findsOneWidget);
    });

    testWidgets('should handle many cables', (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShelvingSummary(
              targetLocation: 'A01-01-01',
              cableCount: 99,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('99 条'), findsOneWidget);
    });

    testWidgets('should handle special characters in location',
        (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShelvingSummary(
              targetLocation: 'A01/B02-03#04',
              cableCount: 5,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('A01/B02-03#04'), findsOneWidget);
    });

    testWidgets('should have different card color when ready', (tester) async {
      // Act - Not ready
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShelvingSummary(
              targetLocation: null,
              cableCount: 0,
            ),
          ),
        ),
      );

      // Get card widget when not ready
      final notReadyCard = tester.widget<Card>(find.byType(Card));

      // Act - Ready
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShelvingSummary(
              targetLocation: 'A01-01-01',
              cableCount: 5,
            ),
          ),
        ),
      );

      // Get card widget when ready
      final readyCard = tester.widget<Card>(find.byType(Card));

      // Assert - Different colors
      expect(notReadyCard.color, isNot(equals(readyCard.color)));
    });

    testWidgets('should prioritize location warning over cable warning',
        (tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ShelvingSummary(
              targetLocation: null,
              cableCount: 0,
            ),
          ),
        ),
      );

      // Assert - Only location warning shown
      expect(find.text('请先设置目标库位'), findsOneWidget);
      expect(find.text('请添加至少一条电缆'), findsNothing);
    });
  });
}
