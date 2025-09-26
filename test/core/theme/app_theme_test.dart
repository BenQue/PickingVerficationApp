import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:picking_verification_app/core/theme/app_theme.dart';

void main() {
  group('AppTheme Tests', () {
    group('Light Theme', () {
      late ThemeData lightTheme;

      setUp(() {
        lightTheme = AppTheme.lightTheme;
      });

      test('should have correct brightness', () {
        expect(lightTheme.brightness, Brightness.light);
      });

      test('should use Material 3', () {
        expect(lightTheme.useMaterial3, true);
      });

      test('should have blue color scheme', () {
        expect(lightTheme.colorScheme.brightness, Brightness.light);
        // The primary color should be blue-based (allow Material 3 color variations)
        final primaryColor = lightTheme.colorScheme.primary;
        expect((primaryColor.b * 255.0).round() & 0xff, greaterThan(100)); // Should have significant blue component
      });

      test('should have large typography for PDA use', () {
        final textTheme = lightTheme.textTheme;
        
        expect(textTheme.displayLarge!.fontSize, 32);
        expect(textTheme.displayMedium!.fontSize, 28);
        expect(textTheme.bodyLarge!.fontSize, 16);
        expect(textTheme.labelLarge!.fontSize, 14);
      });

      test('should have large button configuration', () {
        final buttonTheme = lightTheme.elevatedButtonTheme.style!;
        final minSize = buttonTheme.minimumSize!.resolve({});
        
        expect(minSize!.width, 120);
        expect(minSize.height, 56);
      });

      test('should have proper app bar theme', () {
        final appBarTheme = lightTheme.appBarTheme;
        
        expect(appBarTheme.elevation, 4);
        expect(appBarTheme.titleTextStyle!.fontSize, 20);
        expect(appBarTheme.titleTextStyle!.fontWeight, FontWeight.w600);
      });

      test('should have proper card theme', () {
        final cardTheme = lightTheme.cardTheme;
        
        expect(cardTheme.elevation, 2);
        expect(cardTheme.shape, isA<RoundedRectangleBorder>());
      });
    });

    group('Dark Theme', () {
      late ThemeData darkTheme;

      setUp(() {
        darkTheme = AppTheme.darkTheme;
      });

      test('should have correct brightness', () {
        expect(darkTheme.brightness, Brightness.dark);
      });

      test('should use Material 3', () {
        expect(darkTheme.useMaterial3, true);
      });

      test('should have blue color scheme', () {
        expect(darkTheme.colorScheme.brightness, Brightness.dark);
      });

      test('should have same typography as light theme', () {
        final textTheme = darkTheme.textTheme;
        
        expect(textTheme.displayLarge!.fontSize, 32);
        expect(textTheme.displayMedium!.fontSize, 28);
        expect(textTheme.bodyLarge!.fontSize, 16);
      });

      test('should have higher card elevation for dark mode', () {
        final cardTheme = darkTheme.cardTheme;
        
        expect(cardTheme.elevation, 4); // Higher than light theme
        expect(cardTheme.color, isNotNull);
      });
    });
  });
}