import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/picking_verification/presentation/widgets/manual_input_widget.dart';

void main() {
  Widget createWidgetUnderTest() {
    return const MaterialApp(
      home: Scaffold(
        body: ManualInputWidget(),
      ),
    );
  }

  group('ManualInputWidget', () {
    testWidgets('should display basic UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('手动输入订单号'), findsOneWidget);
      expect(find.text('请输入订单编号'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('查询订单'), findsOneWidget);
    });

    testWidgets('should display submit button', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final submitButton = find.widgetWithText(ElevatedButton, '查询订单');
      expect(submitButton, findsOneWidget);
    });

    testWidgets('should convert input to uppercase', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'ord123456');
      await tester.pump();

      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.controller?.text, equals('ORD123456'));
    });

    testWidgets('should show clear button when text entered', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'test');
      await tester.pump();

      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets('should clear text when clear button pressed', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final textField = find.byType(TextField);
      await tester.enterText(textField, 'test');
      await tester.pump();

      final clearButton = find.byIcon(Icons.clear);
      await tester.tap(clearButton);
      await tester.pump();

      final textFieldWidget = tester.widget<TextField>(textField);
      expect(textFieldWidget.controller?.text, equals(''));
    });

    testWidgets('should display input hints and tips', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('例如: ORD20250905001'), findsOneWidget);
      expect(find.text('输入提示'), findsOneWidget);
      expect(find.text('• 订单号通常以 ORD 开头\n• 长度为 6-20 个字符\n• 支持字母和数字'), findsOneWidget);
    });

    testWidgets('should have industrial PDA design standards', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Check large font sizes
      final titleText = tester.widget<Text>(find.text('手动输入订单号'));
      expect(titleText.style?.fontSize, equals(22));
      expect(titleText.style?.fontWeight, equals(FontWeight.bold));

      // Check large input field
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.style?.fontSize, equals(20));
      expect(textField.style?.fontWeight, equals(FontWeight.w500));

      // Check large submit button
      final submitText = tester.widget<Text>(find.text('查询订单'));
      expect(submitText.style?.fontSize, equals(20));
      expect(submitText.style?.fontWeight, equals(FontWeight.bold));
    });
  });
}