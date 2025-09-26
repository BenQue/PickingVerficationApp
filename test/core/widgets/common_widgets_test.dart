import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/core/widgets/common_widgets.dart' as app_widgets;

void main() {
  group('Common Widgets Tests', () {
    group('PrimaryButton', () {
      testWidgets('should display text correctly', (tester) async {
        const buttonText = 'Test Button';
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: app_widgets.PrimaryButton(
                text: buttonText,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.text(buttonText), findsOneWidget);
      });

      testWidgets('should show loading indicator when loading', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: app_widgets.PrimaryButton(
                text: 'Loading Button',
                isLoading: true,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should be disabled when onPressed is null', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: app_widgets.PrimaryButton(
                text: 'Disabled Button',
                onPressed: null,
              ),
            ),
          ),
        );

        final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
        expect(button.onPressed, isNull);
      });

      testWidgets('should show icon when provided', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: app_widgets.PrimaryButton(
                text: 'Icon Button',
                icon: Icons.add,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.add), findsOneWidget);
      });
    });

    group('SecondaryButton', () {
      testWidgets('should display text correctly', (tester) async {
        const buttonText = 'Secondary Button';
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: app_widgets.SecondaryButton(
                text: buttonText,
                onPressed: () {},
              ),
            ),
          ),
        );

        expect(find.text(buttonText), findsOneWidget);
        expect(find.byType(OutlinedButton), findsOneWidget);
      });
    });

    group('LoadingWidget', () {
      testWidgets('should display loading indicator', (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: app_widgets.LoadingWidget(),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
      });

      testWidgets('should display message when provided', (tester) async {
        const message = 'Loading data...';
        
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: app_widgets.LoadingWidget(message: message),
            ),
          ),
        );

        expect(find.text(message), findsOneWidget);
      });
    });

    group('AppErrorWidget', () {
      testWidgets('should display error message', (tester) async {
        const errorMessage = 'Something went wrong';
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: app_widgets.ErrorWidget(message: errorMessage),
            ),
          ),
        );

        expect(find.text('出错了'), findsOneWidget);
        expect(find.text(errorMessage), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
      });

      testWidgets('should show retry button when onRetry provided', (tester) async {
        bool retryPressed = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: app_widgets.ErrorWidget(
                message: 'Error message',
                onRetry: () => retryPressed = true,
              ),
            ),
          ),
        );

        expect(find.text('重试'), findsOneWidget);
        
        await tester.tap(find.text('重试'));
        expect(retryPressed, true);
      });
    });

    group('SuccessWidget', () {
      testWidgets('should display success message', (tester) async {
        const successMessage = 'Operation completed';
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: app_widgets.SuccessWidget(message: successMessage),
            ),
          ),
        );

        expect(find.text('操作成功'), findsOneWidget);
        expect(find.text(successMessage), findsOneWidget);
        expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      });
    });

    group('AppCard', () {
      testWidgets('should render child content', (tester) async {
        const childText = 'Card content';
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: app_widgets.AppCard(
                child: Text(childText),
              ),
            ),
          ),
        );

        expect(find.text(childText), findsOneWidget);
        expect(find.byType(Card), findsOneWidget);
      });

      testWidgets('should be tappable when onTap provided', (tester) async {
        bool cardTapped = false;
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: app_widgets.AppCard(
                onTap: () => cardTapped = true,
                child: const Text('Tappable card'),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(app_widgets.AppCard));
        expect(cardTapped, true);
      });
    });

    group('AppTextFormField', () {
      testWidgets('should display label', (tester) async {
        const labelText = 'Test Field';
        
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: app_widgets.AppTextFormField(label: labelText),
            ),
          ),
        );

        expect(find.text(labelText), findsOneWidget);
      });

      testWidgets('should show prefix icon when provided', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: app_widgets.AppTextFormField(
                label: 'Field with icon',
                prefixIcon: Icons.person,
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.person), findsOneWidget);
      });

      testWidgets('should be disabled when enabled is false', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: app_widgets.AppTextFormField(
                label: 'Disabled field',
                enabled: false,
              ),
            ),
          ),
        );

        final textField = tester.widget<TextFormField>(find.byType(TextFormField));
        expect(textField.enabled, false);
      });
    });
  });
}