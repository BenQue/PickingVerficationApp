import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/features/picking_verification/presentation/widgets/submission_progress_widget.dart';

void main() {
  group('SubmissionProgressWidget', () {
    Widget createTestWidget({
      required String message,
      required double progress,
      bool showCancel = true,
      VoidCallback? onCancel,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SubmissionProgressWidget(
            message: message,
            progress: progress,
            showCancel: showCancel,
            onCancel: onCancel,
          ),
        ),
      );
    }

    testWidgets('should display progress message', (tester) async {
      const message = '正在验证数据...';
      
      await tester.pumpWidget(createTestWidget(
        message: message,
        progress: 0.5,
      ));

      expect(find.text(message), findsOneWidget);
    });

    testWidgets('should show linear progress indicator with correct value', (tester) async {
      const progress = 0.7;
      
      await tester.pumpWidget(createTestWidget(
        message: '处理中...',
        progress: progress,
      ));

      final progressIndicator = find.byType(LinearProgressIndicator);
      expect(progressIndicator, findsOneWidget);
      
      final progressWidget = tester.widget<LinearProgressIndicator>(progressIndicator);
      expect(progressWidget.value, equals(progress));
    });

    testWidgets('should display progress percentage', (tester) async {
      const progress = 0.75;
      
      await tester.pumpWidget(createTestWidget(
        message: '上传中...',
        progress: progress,
      ));

      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('should show cancel button when enabled', (tester) async {
      bool cancelCalled = false;
      
      await tester.pumpWidget(createTestWidget(
        message: '处理中...',
        progress: 0.3,
        showCancel: true,
        onCancel: () => cancelCalled = true,
      ));

      final cancelButton = find.text('取消');
      expect(cancelButton, findsOneWidget);
      
      await tester.tap(cancelButton);
      expect(cancelCalled, isTrue);
    });

    testWidgets('should hide cancel button when disabled', (tester) async {
      await tester.pumpWidget(createTestWidget(
        message: '最终处理中...',
        progress: 0.95,
        showCancel: false,
      ));

      expect(find.text('取消'), findsNothing);
    });

    testWidgets('should handle progress values correctly', (tester) async {
      final progressValues = [0.0, 0.25, 0.5, 0.75, 1.0];
      
      for (final progress in progressValues) {
        await tester.pumpWidget(createTestWidget(
          message: '测试进度',
          progress: progress,
        ));
        
        final expectedPercentage = '${(progress * 100).round()}%';
        expect(find.text(expectedPercentage), findsOneWidget);
        
        final progressIndicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(progressIndicator.value, equals(progress));
      }
    });

    testWidgets('should show indeterminate progress when value is null', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SubmissionProgressWidget(
              message: '连接服务器...',
              progress: null,
            ),
          ),
        ),
      );

      final progressIndicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(progressIndicator.value, isNull);
      
      // Should not show percentage for indeterminate progress
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('should have proper layout and spacing', (tester) async {
      await tester.pumpWidget(createTestWidget(
        message: '数据处理中...',
        progress: 0.6,
      ));

      // Check that message is above progress indicator
      final messagePosition = tester.getTopLeft(find.text('数据处理中...'));
      final progressPosition = tester.getTopLeft(find.byType(LinearProgressIndicator));
      expect(messagePosition.dy, lessThan(progressPosition.dy));

      // Check that percentage is displayed
      final percentagePosition = tester.getTopLeft(find.text('60%'));
      expect(percentagePosition.dy, greaterThan(progressPosition.dy));
    });

    testWidgets('should use proper text styles for PDA', (tester) async {
      await tester.pumpWidget(createTestWidget(
        message: '上传验证数据...',
        progress: 0.4,
      ));

      final messageText = tester.widget<Text>(find.text('上传验证数据...'));
      expect(messageText.style?.fontSize, greaterThanOrEqualTo(16));

      final percentageText = tester.widget<Text>(find.text('40%'));
      expect(percentageText.style?.fontSize, greaterThanOrEqualTo(14));
      expect(percentageText.style?.fontWeight, equals(FontWeight.bold));
    });

    testWidgets('should handle cancel button accessibility', (tester) async {
      await tester.pumpWidget(createTestWidget(
        message: '处理中...',
        progress: 0.5,
        onCancel: () {},
      ));

      final cancelButton = find.text('取消');
      final semantics = tester.getSemantics(cancelButton);
      
      expect(semantics.hasEnabledState, isTrue);
      expect(semantics.label, contains('取消'));
    });

    testWidgets('should animate progress changes smoothly', (tester) async {
      await tester.pumpWidget(createTestWidget(
        message: '处理中...',
        progress: 0.3,
      ));

      // Verify initial progress
      expect(find.text('30%'), findsOneWidget);

      // Update progress
      await tester.pumpWidget(createTestWidget(
        message: '处理中...',
        progress: 0.7,
      ));
      await tester.pumpAndSettle();

      // Verify updated progress
      expect(find.text('70%'), findsOneWidget);
    });

    testWidgets('should display different message types correctly', (tester) async {
      final messages = [
        '正在验证订单数据...',
        '上传到服务器...',
        '生成审计记录...',
        '完成最后步骤...',
      ];

      for (final message in messages) {
        await tester.pumpWidget(createTestWidget(
          message: message,
          progress: 0.5,
        ));

        expect(find.text(message), findsOneWidget);
      }
    });

    testWidgets('should handle edge cases gracefully', (tester) async {
      // Test with progress > 1.0
      await tester.pumpWidget(createTestWidget(
        message: '处理完成',
        progress: 1.2,
      ));

      // Should clamp to 100%
      expect(find.text('100%'), findsOneWidget);

      // Test with negative progress
      await tester.pumpWidget(createTestWidget(
        message: '开始处理',
        progress: -0.1,
      ));

      // Should clamp to 0%
      expect(find.text('0%'), findsOneWidget);
    });
  });
}