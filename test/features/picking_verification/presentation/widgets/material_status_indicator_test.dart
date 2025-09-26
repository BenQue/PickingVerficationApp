import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/picking_verification/domain/entities/material_item.dart';
import 'package:picking_verification_app/features/picking_verification/presentation/widgets/material_status_indicator.dart';

void main() {
  group('MaterialStatusIndicator Widget Tests', () {
    testWidgets('should display correct icon and color for pending status', (WidgetTester tester) async {
      // Arrange
      const status = MaterialStatus.pending;
      
      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MaterialStatusIndicator(
            status: status,
            showLabel: true,
            compact: false,
          ),
        ),
      ));
      
      // Assert
      expect(find.byType(Icon), findsOneWidget);
      expect(find.text('待处理'), findsOneWidget);
      
      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      expect(iconWidget.icon, Icons.access_time);
    });

    testWidgets('should display correct icon and color for completed status', (WidgetTester tester) async {
      // Arrange  
      const status = MaterialStatus.completed;
      
      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MaterialStatusIndicator(
            status: status,
            showLabel: true,
            compact: false,
          ),
        ),
      ));
      
      // Assert
      expect(find.byType(Icon), findsOneWidget);
      expect(find.text('已完成'), findsOneWidget);
      
      final iconWidget = tester.widget<Icon>(find.byType(Icon));
      expect(iconWidget.icon, Icons.check_circle);
    });

    testWidgets('should display compact mode correctly', (WidgetTester tester) async {
      // Arrange
      const status = MaterialStatus.inProgress;
      
      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MaterialStatusIndicator(
            status: status,
            showLabel: false,
            compact: true,
          ),
        ),
      ));
      
      // Assert
      expect(find.byType(Icon), findsOneWidget);
      expect(find.text('处理中'), findsNothing); // No label in compact mode
    });

    testWidgets('should apply correct PDA touch target size', (WidgetTester tester) async {
      // Arrange
      const status = MaterialStatus.error;
      
      // Act
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MaterialStatusIndicator(
            status: status,
            iconSize: 24,
          ),
        ),
      ));
      
      // Assert - Check container has proper sizing
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsOneWidget);
      
      final containerWidget = tester.widget<Container>(containerFinder);
      expect(containerWidget.padding, isNotNull);
    });
  });
}