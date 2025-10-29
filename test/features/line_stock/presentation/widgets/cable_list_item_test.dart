import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/line_stock/domain/entities/cable_item.dart';
import 'package:picking_verification_app/features/line_stock/presentation/widgets/cable_list_item.dart';

void main() {
  group('CableListItem', () {
    final testCable = CableItem(
      barcode: 'CABLE-001',
      materialCode: 'MAT-001',
      materialDesc: 'Test Cable Description',
      currentLocation: 'A01-01-01',
    );

    testWidgets('should display index number', (tester) async {
      // Arrange
      bool deleted = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CableListItem(
              index: 0,
              cable: testCable,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('1'), findsOneWidget); // Index is 0-based, display is 1-based
    });

    testWidgets('should display cable barcode', (tester) async {
      // Arrange
      bool deleted = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CableListItem(
              index: 0,
              cable: testCable,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('CABLE-001'), findsOneWidget);
    });

    testWidgets('should display cable display info', (tester) async {
      // Arrange
      bool deleted = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CableListItem(
              index: 0,
              cable: testCable,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('MAT-001 - Test Cable Description'), findsOneWidget);
    });

    testWidgets('should display current location', (tester) async {
      // Arrange
      bool deleted = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CableListItem(
              index: 0,
              cable: testCable,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('当前位置: A01-01-01'), findsOneWidget);
      expect(find.byIcon(Icons.location_on_outlined), findsOneWidget);
    });

    testWidgets('should display delete button', (tester) async {
      // Arrange
      bool deleted = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CableListItem(
              index: 0,
              cable: testCable,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });

    testWidgets('should call onDelete when delete button tapped',
        (tester) async {
      // Arrange
      bool deleted = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CableListItem(
              index: 0,
              cable: testCable,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      // Tap delete button
      await tester.tap(find.byIcon(Icons.delete_outline));
      await tester.pumpAndSettle();

      // Assert
      expect(deleted, true);
    });

    testWidgets('should display correct index for different positions',
        (tester) async {
      // Arrange
      bool deleted = false;

      // Act - Index 5 (should display as 6)
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CableListItem(
              index: 5,
              cable: testCable,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('6'), findsOneWidget);
    });

    testWidgets('should be wrapped in a Card', (tester) async {
      // Arrange
      bool deleted = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CableListItem(
              index: 0,
              cable: testCable,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('should have circular index indicator', (tester) async {
      // Arrange
      bool deleted = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CableListItem(
              index: 0,
              cable: testCable,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      // Assert
      final containerFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Container &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).shape == BoxShape.circle,
      );
      expect(containerFinder, findsOneWidget);
    });

    testWidgets('should handle long material description', (tester) async {
      // Arrange
      bool deleted = false;
      final longDescCable = CableItem(
        barcode: 'CABLE-LONG',
        materialCode: 'MAT-LONG',
        materialDesc:
            'This is a very long cable description that should be ellipsized when displayed in the list item to prevent overflow',
        currentLocation: 'B01-01-01',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CableListItem(
              index: 0,
              cable: longDescCable,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      // Assert - Description is displayed (may be ellipsized)
      expect(find.textContaining('MAT-LONG'), findsOneWidget);
    });

    testWidgets('should handle special characters in barcode', (tester) async {
      // Arrange
      bool deleted = false;
      final specialCable = CableItem(
        barcode: 'CABLE-001/A#B',
        materialCode: 'MAT-SPECIAL',
        materialDesc: 'Special & Characters',
        currentLocation: 'C01/D01-01',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CableListItem(
              index: 0,
              cable: specialCable,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('CABLE-001/A#B'), findsOneWidget);
      expect(find.text('MAT-SPECIAL - Special & Characters'), findsOneWidget);
      expect(find.text('当前位置: C01/D01-01'), findsOneWidget);
    });

    testWidgets('should have large touch target for delete button',
        (tester) async {
      // Arrange
      bool deleted = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CableListItem(
              index: 0,
              cable: testCable,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      // Assert - Container has minimum size for touch target
      final deleteButtonContainer = tester.widget<Container>(
        find.ancestor(
          of: find.byIcon(Icons.delete_outline),
          matching: find.byType(Container),
        ).first,
      );
      expect(deleteButtonContainer.constraints?.minWidth, 56);
      expect(deleteButtonContainer.constraints?.minHeight, 56);
    });

    testWidgets('should display items in correct order in a list',
        (tester) async {
      // Arrange
      bool deleted1 = false;
      bool deleted2 = false;
      final cable1 = CableItem(
        barcode: 'CABLE-001',
        materialCode: 'MAT-001',
        materialDesc: 'First Cable',
        currentLocation: 'A01',
      );
      final cable2 = CableItem(
        barcode: 'CABLE-002',
        materialCode: 'MAT-002',
        materialDesc: 'Second Cable',
        currentLocation: 'A02',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView(
              children: [
                CableListItem(
                  index: 0,
                  cable: cable1,
                  onDelete: () => deleted1 = true,
                ),
                CableListItem(
                  index: 1,
                  cable: cable2,
                  onDelete: () => deleted2 = true,
                ),
              ],
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('CABLE-001'), findsOneWidget);
      expect(find.text('CABLE-002'), findsOneWidget);
    });

    testWidgets('should have correct icon size', (tester) async {
      // Arrange
      bool deleted = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CableListItem(
              index: 0,
              cable: testCable,
              onDelete: () => deleted = true,
            ),
          ),
        ),
      );

      // Assert - Delete icon size
      final deleteIcon =
          tester.widget<Icon>(find.byIcon(Icons.delete_outline));
      expect(deleteIcon.size, 28);

      // Assert - Location icon size
      final locationIcon =
          tester.widget<Icon>(find.byIcon(Icons.location_on_outlined));
      expect(locationIcon.size, 16);
    });
  });
}
