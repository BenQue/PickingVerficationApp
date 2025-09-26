import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/picking_verification/data/datasources/simple_picking_datasource.dart';
import 'features/picking_verification/data/repositories/simple_picking_repository_impl.dart';
import 'features/picking_verification/presentation/bloc/simple_picking_bloc.dart';
import 'features/picking_verification/domain/entities/simple_picking_entities.dart';
import 'core/theme/app_theme.dart';

/// 简单的API测试应用
void main() {
  runApp(const SimpleApiTestApp());
}

class SimpleApiTestApp extends StatelessWidget {
  const SimpleApiTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Simple API Test',
      theme: AppTheme.lightTheme,
      home: BlocProvider(
        create: (context) => SimplePickingBloc(
          repository: SimplePickingRepositoryImpl(
            dataSource: SimplePickingDataSource(),
          ),
        ),
        child: const ApiTestScreen(),
      ),
    );
  }
}

class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  final _controller = TextEditingController(text: '123456789');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Mock Data Test'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<SimplePickingBloc, SimplePickingState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '测试订单号:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        style: const TextStyle(fontSize: 18),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: '输入订单号',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final orderNo = _controller.text.trim();
                        if (orderNo.isNotEmpty) {
                          context
                              .read<SimplePickingBloc>()
                              .add(LoadWorkOrder(orderNo));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      child: const Text('加载', style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  '可用测试订单号:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTestButton('123456789', '完整数据'),
                    _buildTestButton('TEST001', '完整数据'),
                    _buildTestButton('TEST002', '空数据'),
                    _buildTestButton('TEST003', '部分完成'),
                    _buildTestButton('TEST004', '大数据集'),
                    _buildTestButton('ERROR', '错误测试'),
                    _buildTestButton('RANDOM', '随机数据'),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildStateDisplay(state),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTestButton(String orderNo, String description) {
    return ElevatedButton(
      onPressed: () {
        _controller.text = orderNo;
        context.read<SimplePickingBloc>().add(LoadWorkOrder(orderNo));
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(orderNo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          Text(description, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildStateDisplay(SimplePickingState state) {
    if (state is SimplePickingInitial) {
      return const Center(
        child: Text(
          '请选择测试订单号进行测试',
          style: TextStyle(fontSize: 18),
        ),
      );
    } else if (state is SimplePickingLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载数据...', style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    } else if (state is SimplePickingLoaded) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '工单信息: ${state.workOrder.orderNo}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('操作号: ${state.workOrder.operationNo}'),
            Text('状态: ${state.workOrder.operationStatus}'),
            const SizedBox(height: 16),
            _buildMaterialSection('断线物料', state.workOrder.cableMaterials),
            _buildMaterialSection('中央仓库物料', state.workOrder.centerMaterials),
            _buildMaterialSection('自动化仓库物料', state.workOrder.autoMaterials),
          ],
        ),
      );
    } else if (state is SimplePickingError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              '错误: ${state.message}',
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return const SizedBox();
  }

  Widget _buildMaterialSection(String title, List<SimpleMaterial> materials) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$title (${materials.length}项)',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        ...materials.map((material) => Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 4),
          child: Text(
            '${material.materialCode}: ${material.materialDesc} (${material.completedQuantity}/${material.quantity})',
            style: const TextStyle(fontSize: 14),
          ),
        )),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}