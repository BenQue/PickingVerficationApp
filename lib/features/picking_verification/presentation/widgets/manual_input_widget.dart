import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/picking_verification_bloc.dart';
import '../bloc/picking_verification_event.dart';

/// 手动输入订单号组件
/// 提供备用的手动输入方式
class ManualInputWidget extends StatefulWidget {
  const ManualInputWidget({Key? key}) : super(key: key);

  @override
  State<ManualInputWidget> createState() => _ManualInputWidgetState();
}

class _ManualInputWidgetState extends State<ManualInputWidget> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String? _errorText;

  @override
  void initState() {
    super.initState();
    // 自动聚焦输入框
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _validateAndSubmit() {
    final String orderNumber = _controller.text.trim();
    
    // 基本验证
    if (orderNumber.isEmpty) {
      setState(() {
        _errorText = '请输入订单号';
      });
      return;
    }
    
    // 订单号格式验证（示例：要求至少6位）
    if (orderNumber.length < 6) {
      setState(() {
        _errorText = '订单号格式不正确';
      });
      return;
    }
    
    // 清除错误
    setState(() {
      _errorText = null;
    });
    
    // 提交订单号
    context.read<PickingVerificationBloc>().add(
      EnterOrderManually(orderNumber: orderNumber),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 标题栏
          Row(
            children: [
              const Icon(
                Icons.edit_note,
                size: 32,
                color: Colors.blue,
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '手动输入订单号',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // 切换到扫描模式按钮
              TextButton.icon(
                onPressed: () {
                  context.read<PickingVerificationBloc>().add(
                    StartScanning(),
                  );
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('扫描'),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).primaryColor,
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // 输入提示
          const Text(
            '请输入订单编号',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          
          // 输入框
          TextField(
            controller: _controller,
            focusNode: _focusNode,
            decoration: InputDecoration(
              hintText: '例如: ORD20250905001',
              errorText: _errorText,
              prefixIcon: const Icon(
                Icons.receipt_long,
                size: 28,
              ),
              suffixIcon: _controller.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 28),
                      onPressed: () {
                        _controller.clear();
                        setState(() {
                          _errorText = null;
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(width: 2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  width: 2,
                  color: Colors.grey.shade400,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  width: 3,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  width: 2,
                  color: Colors.red,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 20,
              ),
              hintStyle: const TextStyle(fontSize: 18),
              errorStyle: const TextStyle(fontSize: 16),
            ),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              // 转换为大写
              TextInputFormatter.withFunction(
                (oldValue, newValue) => TextEditingValue(
                  text: newValue.text.toUpperCase(),
                  selection: newValue.selection,
                ),
              ),
              // 限制长度
              LengthLimitingTextInputFormatter(20),
            ],
            onChanged: (value) {
              if (_errorText != null) {
                setState(() {
                  _errorText = null;
                });
              }
              setState(() {}); // 更新清除按钮显示
            },
            onSubmitted: (_) => _validateAndSubmit(),
            textInputAction: TextInputAction.done,
          ),
          
          const SizedBox(height: 32),
          
          // 确认按钮
          ElevatedButton(
            onPressed: _validateAndSubmit,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 28),
                SizedBox(width: 12),
                Text(
                  '查询订单',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 使用说明
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.shade200,
                width: 1,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.blue,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      '输入提示',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '• 订单号通常以 ORD 开头\n'
                  '• 长度为 6-20 个字符\n'
                  '• 支持字母和数字',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}