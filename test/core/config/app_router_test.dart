import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/core/config/app_router.dart';
import 'package:picking_verification_app/features/auth/presentation/pages/login_screen.dart';
import 'package:picking_verification_app/features/task_board/presentation/pages/task_board_screen.dart';
import 'package:picking_verification_app/features/picking_verification/presentation/pages/picking_verification_screen.dart';

void main() {
  group('AppRouter Tests', () {
    test('should have correct route constants', () {
      expect(AppRouter.loginRoute, '/login');
      expect(AppRouter.tasksRoute, '/tasks');
      expect(AppRouter.pickingVerificationRoute, '/picking-verification');
      expect(AppRouter.platformReceivingRoute, '/platform-receiving');
      expect(AppRouter.lineDeliveryRoute, '/line-delivery');
    });

    group('Placeholder Pages', () {
      testWidgets('LoginPlaceholderPage should display correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: const LoginScreen(),
          ),
        );

        expect(find.text('登录'), findsOneWidget);
        expect(find.text('登录页面 - 待实现'), findsOneWidget);
      });

      testWidgets('TaskBoardPlaceholderPage should display correctly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: const TaskBoardScreen(),
          ),
        );

        expect(find.text('任务看板'), findsOneWidget);
        expect(find.text('任务看板页面 - 待实现'), findsOneWidget);
      });

      testWidgets('PickingVerificationPlaceholderPage should display order ID', (tester) async {
        const orderId = 'ORDER123';
        
        await tester.pumpWidget(
          MaterialApp(
            home: PickingVerificationScreen(orderNumber: orderId),
          ),
        );

        expect(find.text('合箱校验'), findsOneWidget);
        expect(find.text('订单ID: $orderId'), findsOneWidget);
      });

      testWidgets('ErrorPage should display error message', (tester) async {
        const errorMessage = 'Test error message';
        
        await tester.pumpWidget(
          MaterialApp(
            home: const ErrorPage(error: errorMessage),
          ),
        );

        expect(find.text('错误'), findsOneWidget);
        expect(find.text('页面加载出错'), findsOneWidget);
        expect(find.text(errorMessage), findsOneWidget);
        expect(find.text('返回首页'), findsOneWidget);
      });
    });
  });
}