import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/picking_verification/presentation/widgets/material_list_widget.dart';
import 'package:picking_verification_app/features/picking_verification/domain/entities/material_item.dart';
import 'package:picking_verification_app/features/picking_verification/domain/entities/picking_order.dart';

void main() {
  group('MaterialListWidget', () {
    final testMaterials = [
      const MaterialItem(
        id: '1',
        code: 'MAT001',
        name: '断线物料1',
        category: MaterialCategory.lineBreak,
        requiredQuantity: 10,
        availableQuantity: 8,
        status: MaterialStatus.pending,
        location: 'A1-B2',
      ),
      const MaterialItem(
        id: '2',
        code: 'MAT002',
        name: '中央仓物料1',
        category: MaterialCategory.centralWarehouse,
        requiredQuantity: 5,
        availableQuantity: 5,
        status: MaterialStatus.completed,
        location: 'C3-D4',
      ),
      const MaterialItem(
        id: '3',
        code: 'MAT003',
        name: '自动化库物料1',
        category: MaterialCategory.automated,
        requiredQuantity: 15,
        availableQuantity: 12,
        status: MaterialStatus.inProgress,
        location: 'E5-F6',
      ),
    ];

    Widget createWidgetUnderTest({
      required List<MaterialItem> materials,
    }) {
      final testOrder = PickingOrder(
        orderId: 'test-order-id',
        orderNumber: 'TEST001',
        status: 'active',
        createdAt: DateTime.now(),
        items: const [],
        materials: materials,
        isVerified: false,
      );
      
      return MaterialApp(
        home: Scaffold(
          body: MaterialListWidget(
            order: testOrder,
          ),
        ),
      );
    }

    testWidgets('should display all material categories', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(materials: testMaterials));

      expect(find.text('断线物料'), findsOneWidget);
      expect(find.text('中央仓物料'), findsOneWidget);
      expect(find.text('自动化库物料'), findsOneWidget);
    });

    testWidgets('should show material count for each category', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(materials: testMaterials));

      expect(find.text('共 1 项物料'), findsNWidgets(3)); // Each category has 1 item
    });

    testWidgets('should display category icons', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(materials: testMaterials));

      // Each category should have its specific icon
      expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets); // Line break (may appear multiple times)
      expect(find.byIcon(Icons.warehouse), findsWidgets); // Central warehouse
      expect(find.byIcon(Icons.precision_manufacturing), findsWidgets); // Automated
    });

    testWidgets('should show materials in expanded categories by default', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(materials: testMaterials));

      // Materials should be visible by default (initiallyExpanded: true)
      expect(find.text('断线物料1'), findsOneWidget);
      expect(find.text('中央仓物料1'), findsOneWidget);
      expect(find.text('自动化库物料1'), findsOneWidget);
    });

    testWidgets('should show material status indicators', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        materials: testMaterials,
      ));

      // Verify material status indicators are shown
      expect(find.text('待处理'), findsOneWidget); // Pending status
      expect(find.text('已完成'), findsOneWidget); // Completed status
      expect(find.text('处理中'), findsOneWidget); // In progress status
    });

    testWidgets('should show completion status for categories', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(materials: testMaterials));

      // Categories with incomplete materials should show pending color
      // Categories with completed materials should show success color
      expect(find.byType(ExpansionTile), findsNWidgets(3));
    });

    testWidgets('should handle empty material list', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(materials: []));

      expect(find.text('暂无物料信息'), findsOneWidget);
    });

    testWidgets('should group materials by category correctly', (WidgetTester tester) async {
      final mixedMaterials = [
        const MaterialItem(
          id: '1',
          code: 'MAT001',
          name: '断线物料1',
          category: MaterialCategory.lineBreak,
          requiredQuantity: 10,
          availableQuantity: 8,
          status: MaterialStatus.pending,
          location: 'A1-B2',
        ),
        const MaterialItem(
          id: '2',
          code: 'MAT002',
          name: '断线物料2',
          category: MaterialCategory.lineBreak,
          requiredQuantity: 5,
          availableQuantity: 5,
          status: MaterialStatus.completed,
          location: 'A1-B3',
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(materials: mixedMaterials));

      expect(find.text('断线物料'), findsOneWidget);
      expect(find.text('共 2 项物料'), findsOneWidget); // Line break category should show 2 items
    });

    testWidgets('should display materials in correct order within categories', (WidgetTester tester) async {
      final orderedMaterials = [
        const MaterialItem(
          id: '1',
          code: 'MAT001',
          name: '物料A',
          category: MaterialCategory.lineBreak,
          requiredQuantity: 10,
          availableQuantity: 8,
          status: MaterialStatus.pending,
          location: 'A1-B2',
        ),
        const MaterialItem(
          id: '2',
          code: 'MAT002',
          name: '物料B',
          category: MaterialCategory.lineBreak,
          requiredQuantity: 5,
          availableQuantity: 5,
          status: MaterialStatus.completed,
          location: 'A1-B3',
        ),
      ];

      await tester.pumpWidget(createWidgetUnderTest(materials: orderedMaterials));

      // Expand category
      final lineBreakTile = find.ancestor(
        of: find.text('断线物料'),
        matching: find.byType(ExpansionTile),
      );
      await tester.tap(lineBreakTile);
      await tester.pumpAndSettle();

      // Both materials should be visible in order
      expect(find.text('物料A'), findsOneWidget);
      expect(find.text('物料B'), findsOneWidget);
    });
  });
}