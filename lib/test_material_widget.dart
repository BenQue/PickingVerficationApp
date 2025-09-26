import 'package:flutter/material.dart';
import 'features/picking_verification/domain/entities/simple_picking_entities.dart';
import 'features/picking_verification/presentation/widgets/simple_material_item_widget.dart';

/// 测试物料组件的应用
void main() {
  runApp(const MaterialWidgetTestApp());
}

class MaterialWidgetTestApp extends StatelessWidget {
  const MaterialWidgetTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Material Widget Test',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(fontSize: 16),
          bodyMedium: TextStyle(fontSize: 14),
        ),
      ),
      home: const MaterialTestScreen(),
    );
  }
}

class MaterialTestScreen extends StatelessWidget {
  const MaterialTestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('物料组件测试'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '物料项目显示测试',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          // 已完成的物料项目 - 应显示绿色✓
          SimpleMaterialItemWidget(
            material: SimpleMaterial(
              itemNo: 'C001',
              materialCode: 'CBL-001',
              materialDesc: '电源线缆 - 220V/50A',
              quantity: 10,
              completedQuantity: 10,
              category: MaterialCategoryType.cable,
            ),
          ),
          // 部分完成的物料项目 - 应显示红色✗
          SimpleMaterialItemWidget(
            material: SimpleMaterial(
              itemNo: 'C002',
              materialCode: 'CBL-002',
              materialDesc: '数据线缆 - CAT6网线',
              quantity: 15,
              completedQuantity: 8,
              category: MaterialCategoryType.center,
            ),
          ),
          // 未开始的物料项目 - 应显示红色✗
          SimpleMaterialItemWidget(
            material: SimpleMaterial(
              itemNo: 'C003',
              materialCode: 'CBL-003',
              materialDesc: '光纤线缆 - 单模9/125',
              quantity: 5,
              completedQuantity: 0,
              category: MaterialCategoryType.auto,
            ),
          ),
          // 超额完成的物料项目 - 应显示绿色✓
          SimpleMaterialItemWidget(
            material: SimpleMaterial(
              itemNo: 'C004',
              materialCode: 'CBL-004',
              materialDesc: '控制线缆 - 24V直流',
              quantity: 12,
              completedQuantity: 15,
              category: MaterialCategoryType.cable,
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              '界面说明：\n'
              '• 绿色背景 + ✓ = 已完成项目\n'
              '• 红色背景 + ✗ = 未完成项目\n'
              '• 数量只读显示，无修改按钮\n'
              '• 无进度条显示',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}