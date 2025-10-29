import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/line_stock/domain/entities/line_stock_entity.dart';
import 'package:picking_verification_app/features/line_stock/presentation/widgets/stock_info_card.dart';

void main() {
  group('StockInfoCard', () {
    final testStock = LineStock(
      materialCode: 'MAT-001',
      materialDesc: 'Test Material Description',
      quantity: 100.0,
      baseUnit: 'PC',
      batchCode: 'BATCH-2024-001',
      locationCode: 'A01-01-01',
      barcode: 'BC-TEST',
    );

    testWidgets('should display all stock information', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockInfoCard(stock: testStock),
          ),
        ),
      );

      // Assert - All information displayed
      expect(find.text('物料信息'), findsOneWidget);
      expect(find.text('MAT-001'), findsOneWidget);
      expect(find.text('Test Material Description'), findsOneWidget);
      expect(find.text('库存状态'), findsOneWidget);
      expect(find.text('100.0 PC'), findsOneWidget);
      expect(find.text('BATCH-2024-001'), findsOneWidget);
      expect(find.text('A01-01-01'), findsOneWidget);
    });

    testWidgets('should display material info section header',
        (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockInfoCard(stock: testStock),
          ),
        ),
      );

      // Assert
      expect(find.text('物料信息'), findsOneWidget);
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
    });

    testWidgets('should display stock status section header', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockInfoCard(stock: testStock),
          ),
        ),
      );

      // Assert
      expect(find.text('库存状态'), findsOneWidget);
      expect(find.byIcon(Icons.analytics_outlined), findsOneWidget);
    });

    testWidgets('should display material code label', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockInfoCard(stock: testStock),
          ),
        ),
      );

      // Assert
      expect(find.text('物料编码'), findsOneWidget);
      expect(find.text('MAT-001'), findsOneWidget);
    });

    testWidgets('should display material description label', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockInfoCard(stock: testStock),
          ),
        ),
      );

      // Assert
      expect(find.text('物料描述'), findsOneWidget);
      expect(find.text('Test Material Description'), findsOneWidget);
    });

    testWidgets('should display quantity info label', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockInfoCard(stock: testStock),
          ),
        ),
      );

      // Assert
      expect(find.text('当前数量'), findsOneWidget);
      expect(find.text('100.0 PC'), findsOneWidget);
    });

    testWidgets('should display batch code label', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockInfoCard(stock: testStock),
          ),
        ),
      );

      // Assert
      expect(find.text('批次号'), findsOneWidget);
      expect(find.text('BATCH-2024-001'), findsOneWidget);
    });

    testWidgets('should display location code label', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockInfoCard(stock: testStock),
          ),
        ),
      );

      // Assert
      expect(find.text('当前库位'), findsOneWidget);
      expect(find.text('A01-01-01'), findsOneWidget);
    });

    testWidgets('should have divider between sections', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockInfoCard(stock: testStock),
          ),
        ),
      );

      // Assert
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('should be wrapped in a Card', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockInfoCard(stock: testStock),
          ),
        ),
      );

      // Assert
      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('should call onTap when tapped', (tester) async {
      // Arrange
      bool tapped = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockInfoCard(
              stock: testStock,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      // Tap the card
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert
      expect(tapped, true);
    });

    testWidgets('should not crash when onTap is null', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockInfoCard(stock: testStock),
          ),
        ),
      );

      // Tap the card (should not crash)
      await tester.tap(find.byType(InkWell));
      await tester.pumpAndSettle();

      // Assert - No crash
      expect(find.byType(StockInfoCard), findsOneWidget);
    });

    testWidgets('should handle zero quantity', (tester) async {
      // Arrange
      final zeroStock = LineStock(
        materialCode: 'MAT-002',
        materialDesc: 'Zero Stock Material',
        quantity: 0.0,
        baseUnit: 'PC',
        batchCode: 'BATCH-ZERO',
        locationCode: 'B01-01-01',
      barcode: 'BC-TEST',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockInfoCard(stock: zeroStock),
          ),
        ),
      );

      // Assert
      expect(find.text('0.0 PC'), findsOneWidget);
    });

    testWidgets('should handle large quantity', (tester) async {
      // Arrange
      final largeStock = LineStock(
        materialCode: 'MAT-003',
        materialDesc: 'Large Stock Material',
        quantity: 99999.5,
        baseUnit: 'KG',
        batchCode: 'BATCH-LARGE',
        locationCode: 'C01-01-01',
      barcode: 'BC-TEST',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockInfoCard(stock: largeStock),
          ),
        ),
      );

      // Assert
      expect(find.text('99999.5 KG'), findsOneWidget);
    });

    testWidgets('should handle different units', (tester) async {
      // Arrange
      final stockKG = LineStock(
        materialCode: 'MAT-KG',
        materialDesc: 'Weight Material',
        quantity: 50.5,
        baseUnit: 'KG',
        batchCode: 'BATCH-KG',
        locationCode: 'D01-01-01',
      barcode: 'BC-TEST',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockInfoCard(stock: stockKG),
          ),
        ),
      );

      // Assert
      expect(find.text('50.5 KG'), findsOneWidget);
    });

    testWidgets('should handle long material description', (tester) async {
      // Arrange
      final longDescStock = LineStock(
        materialCode: 'MAT-LONG',
        materialDesc:
            'This is a very long material description that should be displayed properly without causing overflow issues in the card layout',
        quantity: 10.0,
        baseUnit: 'PC',
        batchCode: 'BATCH-LONG',
        locationCode: 'E01-01-01',
      barcode: 'BC-TEST',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: StockInfoCard(stock: longDescStock),
            ),
          ),
        ),
      );

      // Assert - Description is displayed
      expect(
        find.text(
          'This is a very long material description that should be displayed properly without causing overflow issues in the card layout',
        ),
        findsOneWidget,
      );
    });

    testWidgets('should handle special characters in material code',
        (tester) async {
      // Arrange
      final specialStock = LineStock(
        materialCode: 'MAT-001-A/B',
        materialDesc: 'Special Characters & Symbols',
        quantity: 5.0,
        baseUnit: 'PC',
        batchCode: 'BATCH-2024#001',
        locationCode: 'A01/B01-01',
      barcode: 'BC-TEST',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StockInfoCard(stock: specialStock),
          ),
        ),
      );

      // Assert
      expect(find.text('MAT-001-A/B'), findsOneWidget);
      expect(find.text('Special Characters & Symbols'), findsOneWidget);
      expect(find.text('BATCH-2024#001'), findsOneWidget);
      expect(find.text('A01/B01-01'), findsOneWidget);
    });
  });
}
