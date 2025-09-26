import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mockito/mockito.dart';
import 'package:picking_verification_app/features/picking_verification/presentation/widgets/order_scanning_widget.dart';
import 'package:picking_verification_app/features/picking_verification/presentation/bloc/picking_verification_bloc.dart';

class MockPickingVerificationBloc extends Mock implements PickingVerificationBloc {}

void main() {
  late MockPickingVerificationBloc mockBloc;

  setUp(() {
    mockBloc = MockPickingVerificationBloc();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<PickingVerificationBloc>(
          create: (_) => mockBloc,
          child: const OrderScanningWidget(),
        ),
      ),
    );
  }

  group('OrderScanningWidget', () {
    testWidgets('should display scanning instructions', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('请将二维码置于扫描框内'), findsOneWidget);
      expect(find.byIcon(Icons.qr_code_scanner), findsOneWidget);
    });

    testWidgets('should display torch button', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byIcon(Icons.flash_off), findsOneWidget);
    });

    testWidgets('should display manual input button', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('手动输入'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard), findsOneWidget);
    });

    testWidgets('should display manual input button that can be found', 
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final manualInputButton = find.widgetWithText(ElevatedButton, '手动输入');
      expect(manualInputButton, findsOneWidget);
    });

    testWidgets('should show industrial PDA design elements', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // Verify high contrast black header
      final headerContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(OrderScanningWidget),
          matching: find.byType(Container),
        ).first,
      );
      expect(headerContainer.color, equals(Colors.black87));

      // Verify large font for scanning prompt
      final promptText = tester.widget<Text>(find.text('请将二维码置于扫描框内'));
      expect(promptText.style?.fontSize, equals(18));
      expect(promptText.style?.fontWeight, equals(FontWeight.bold));
    });
  });
}