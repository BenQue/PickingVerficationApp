import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/picking_verification/presentation/widgets/material_item_widget.dart';
import 'package:picking_verification_app/features/picking_verification/domain/entities/material_item.dart';

void main() {
  group('MaterialItemWidget', () {
    const testMaterial = MaterialItem(
      id: '1',
      code: 'MAT001',
      name: '测试物料',
      description: '测试物料描述',
      category: MaterialCategory.centralWarehouse,
      requiredQuantity: 10,
      availableQuantity: 8,
      status: MaterialStatus.pending,
      location: 'A1-B2',
      unit: '个',
      remarks: '测试备注',
    );

    const fulfilledMaterial = MaterialItem(
      id: '2',
      code: 'MAT002',
      name: '充足物料',
      category: MaterialCategory.automated,
      requiredQuantity: 5,
      availableQuantity: 10,
      status: MaterialStatus.completed,
      location: 'C3-D4',
      unit: '盒',
    );

    Widget createWidgetUnderTest({
      required MaterialItem material,
      VoidCallback? onTap,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: MaterialItemWidget(
            material: material,
            onTap: onTap ?? () {},
          ),
        ),
      );
    }

    testWidgets('should display material basic information', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(material: testMaterial));

      expect(find.text('测试物料'), findsOneWidget);
      expect(find.text('MAT001'), findsOneWidget);
      expect(find.text('A1-B2'), findsOneWidget);
    });

    testWidgets('should display quantity information', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(material: testMaterial));

      expect(find.text('8/10 个'), findsOneWidget);
    });

    testWidgets('should show status indicator for pending material', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(material: testMaterial));

      expect(find.text('待处理'), findsOneWidget);
      expect(find.byIcon(Icons.pending), findsOneWidget);
    });

    testWidgets('should show status indicator for completed material', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(material: fulfilledMaterial));

      expect(find.text('已完成'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should show fulfillment status correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(material: testMaterial));

      // Should show shortage for pending material
      expect(find.byIcon(Icons.warning), findsOneWidget);

      await tester.pumpWidget(createWidgetUnderTest(material: fulfilledMaterial));
      await tester.pump();

      // Should show fulfilled for sufficient material
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('should call onTap when widget tapped', (WidgetTester tester) async {
      bool tapped = false;
      await tester.pumpWidget(createWidgetUnderTest(
        material: testMaterial,
        onTap: () => tapped = true,
      ));

      await tester.tap(find.byType(MaterialItemWidget));
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('should display description when available', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(material: testMaterial));

      expect(find.text('测试物料描述'), findsOneWidget);
    });

    testWidgets('should display remarks when available', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(material: testMaterial));

      expect(find.text('测试备注'), findsOneWidget);
    });

    testWidgets('should handle material without optional fields', (WidgetTester tester) async {
      const minimalMaterial = MaterialItem(
        id: '3',
        code: 'MAT003',
        name: '最小物料',
        category: MaterialCategory.lineBreak,
        requiredQuantity: 1,
        availableQuantity: 1,
        status: MaterialStatus.completed,
        location: 'X1-Y2',
      );

      await tester.pumpWidget(createWidgetUnderTest(material: minimalMaterial));

      expect(find.text('最小物料'), findsOneWidget);
      expect(find.text('MAT003'), findsOneWidget);
      expect(find.text('X1-Y2'), findsOneWidget);
      expect(find.text('1/1'), findsOneWidget);
    });

    testWidgets('should use appropriate colors for different statuses', (WidgetTester tester) async {
      // Test different status materials
      const inProgressMaterial = MaterialItem(
        id: '4',
        code: 'MAT004',
        name: '处理中物料',
        category: MaterialCategory.centralWarehouse,
        requiredQuantity: 10,
        availableQuantity: 5,
        status: MaterialStatus.inProgress,
        location: 'B1-C2',
      );

      const errorMaterial = MaterialItem(
        id: '5',
        code: 'MAT005',
        name: '异常物料',
        category: MaterialCategory.automated,
        requiredQuantity: 10,
        availableQuantity: 0,
        status: MaterialStatus.error,
        location: 'D1-E2',
      );

      // Test in progress status
      await tester.pumpWidget(createWidgetUnderTest(material: inProgressMaterial));
      expect(find.text('处理中'), findsOneWidget);
      expect(find.byIcon(Icons.sync), findsOneWidget);

      // Test error status
      await tester.pumpWidget(createWidgetUnderTest(material: errorMaterial));
      await tester.pump();
      expect(find.text('异常'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('should show shortage quantity when not fulfilled', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(material: testMaterial));

      // Material has shortage of 2 (requires 10, available 8)
      expect(find.textContaining('缺少'), findsOneWidget);
    });

    testWidgets('should have industrial PDA design standards', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest(material: testMaterial));

      // Check for large, readable fonts
      final nameText = tester.widget<Text>(find.text('测试物料'));
      expect(nameText.style?.fontSize, greaterThanOrEqualTo(16));
      expect(nameText.style?.fontWeight, equals(FontWeight.w600));

      // Check for high contrast card
      expect(find.byType(Card), findsOneWidget);
      
      // Check for clear visual hierarchy
      expect(find.text('MAT001'), findsOneWidget);
      expect(find.text('A1-B2'), findsOneWidget);
    });
  });
}