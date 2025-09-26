import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'core/config/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/api/dio_client.dart';
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/domain/services/permission_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize DioClient
  DioClient().initialize();
  
  // Configure system UI for industrial PDA use
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  
  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.black,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize exception handling
  AppExceptionHandler.initialize();

  runApp(const PickingVerificationApp());
}

class PickingVerificationApp extends StatelessWidget {
  const PickingVerificationApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Setup dependencies
    const secureStorage = FlutterSecureStorage();
    final dioClient = DioClient();
    
    final authRemoteDataSource = AuthRemoteDataSourceImpl(
      dioClient: dioClient,
    );
    
    final authRepository = AuthRepositoryImpl(
      remoteDataSource: authRemoteDataSource,
      secureStorage: secureStorage,
    );

    final permissionService = PermissionService();

    return MultiProvider(
      providers: [
        Provider<PermissionService>(
          create: (context) => permissionService,
        ),
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(
            authRepository: authRepository,
            permissionService: permissionService,
          ),
        ),
      ],
      child: MaterialApp.router(
        title: '拣配流程追溯与验证程序',
        
        // Apply blue theme
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light, // Default to light theme for industrial use
        
        // Router configuration
        routerConfig: AppRouter.router,
        
        // Disable debug banner in release builds
        debugShowCheckedModeBanner: false,
      
      // Error handling
      builder: (context, child) {
        // Global error boundary
        ErrorWidget.builder = (FlutterErrorDetails details) {
          return MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.red.shade50,
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '应用程序出错',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        details.exception.toString(),
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // This would restart the app in a production environment
                          SystemNavigator.pop();
                        },
                        child: const Text('重启应用'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        };
        
        return child ?? const SizedBox();
      },
      ),
    );
  }
}

/// Global exception handler
class AppExceptionHandler {
  static void initialize() {
    // Handle Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      _logError('Flutter Error', details.exception, details.stack);
    };
    
    // Handle async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      _logError('Platform Error', error, stack);
      return true;
    };
  }
  
  static void _logError(String type, Object error, StackTrace? stack) {
    debugPrint('=== $type ===');
    debugPrint('Error: $error');
    if (stack != null) {
      debugPrint('Stack trace:\n$stack');
    }
    debugPrint('================');
    
    // In production, you would send this to a logging service
    // For now, we just print to console
  }
}
