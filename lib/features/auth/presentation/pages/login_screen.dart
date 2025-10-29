import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../../../../core/config/app_router.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _employeeIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmployeeId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入员工ID';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '请输入密码';
    }
    return null;
  }

  void _onLoginPressed() {
    if (_formKey.currentState?.validate() ?? false) {
      final employeeId = _employeeIdController.text.trim();
      final password = _passwordController.text.trim();
      
      context.read<AuthBloc>().add(AuthLoginRequested(
        employeeId: employeeId,
        password: password,
      ));
    }
  }

  void _handleSuccessfulLogin(BuildContext context, dynamic user) {
    // Navigate to workbench after successful login
    // 登录成功后直接导航到工作台界面
    context.go(AppRouter.workbenchRoute);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('欢迎回来, ${user.name}!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: BlocConsumer<AuthBloc, AuthState>(
            listener: (context, state) {
              if (state is AuthFailure) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 3),
                  ),
                );
              } else if (state is AuthSuccess) {
                // Navigate based on user permissions
                _handleSuccessfulLogin(context, state.user);
              }
            },
            builder: (context, state) {
              final isLoading = state is AuthLoading;
              
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: MediaQuery.of(context).size.height > 48
                        ? MediaQuery.of(context).size.height - 48
                        : MediaQuery.of(context).size.height,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Company logo and title section
                        Column(
                          children: [
                            // Company logo
                            Container(
                              height: 80,
                              width: 80,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Theme.of(context).colorScheme.primaryContainer,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.asset(
                                  'assets/images/company_logo.png',
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      Icons.business,
                                      size: 40,
                                      color: Theme.of(context).colorScheme.primary,
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // Login title
                            Text(
                              '登录',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Subtitle
                            Text(
                              '拣配流程追溯与验证',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Employee ID input
                        AppTextFormField(
                          label: '员工 ID',
                          hint: '请输入您的员工ID',
                          controller: _employeeIdController,
                          validator: _validateEmployeeId,
                          keyboardType: TextInputType.text,
                          prefixIcon: Icons.person_outline,
                          enabled: !isLoading,
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Password input
                        AppTextFormField(
                          label: '密码',
                          hint: '请输入您的密码',
                          controller: _passwordController,
                          validator: _validatePassword,
                          obscureText: true,
                          prefixIcon: Icons.lock_outline,
                          enabled: !isLoading,
                        ),
                        
                        const SizedBox(height: 32),
                        
                        // Login button
                        PrimaryButton(
                          text: '登录',
                          onPressed: isLoading ? null : _onLoginPressed,
                          isLoading: isLoading,
                          icon: Icons.login,
                        ),
                        
                        if (state is AuthFailure) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red.shade300, width: 1.5),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red.shade700,
                                      size: 24,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            '登录失败',
                                            style: TextStyle(
                                              color: Colors.red.shade900,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            state.message,
                                            style: TextStyle(
                                              color: Colors.red.shade700,
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              height: 1.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                // 如果错误信息包含多行或建议，显示额外的提示
                                if (state.message.contains('\n') || 
                                    state.message.contains('请检查') ||
                                    state.message.contains('请联系')) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline,
                                          color: Colors.orange.shade700,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            '如果问题持续存在，请联系技术支持',
                                            style: TextStyle(
                                              color: Colors.orange.shade700,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        
                        // Loading indicator with message
                        if (isLoading)
                          Column(
                            children: [
                              const LoadingWidget(message: '正在登录...'),
                              const SizedBox(height: 12),
                              Text(
                                '请稍候，正在验证您的身份',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}