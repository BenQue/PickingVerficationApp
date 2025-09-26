import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../domain/entities/simple_picking_entities.dart';
import '../bloc/simple_picking_bloc.dart';
import '../widgets/simple_material_item_widget.dart';

/// 简化的拣货验证主屏幕
class SimplePickingScreen extends StatefulWidget {
  const SimplePickingScreen({super.key});

  @override
  State<SimplePickingScreen> createState() => _SimplePickingScreenState();
}

class _SimplePickingScreenState extends State<SimplePickingScreen> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _orderNoController = TextEditingController();
  // bool _isScanning = false; // Removed unused field

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _orderNoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '合箱校验',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: BlocBuilder<SimplePickingBloc, SimplePickingState>(
        builder: (context, state) {
          if (state is SimplePickingInitial) {
            return _buildOrderInputView();
          } else if (state is SimplePickingLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(strokeWidth: 3),
                  SizedBox(height: 16),
                  Text('正在加载工单信息...', style: TextStyle(fontSize: 18)),
                ],
              ),
            );
          } else if (state is SimplePickingLoaded) {
            return _buildWorkOrderView(state.workOrder, state.isModified);
          } else if (state is SimplePickingSubmitting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(strokeWidth: 3),
                  const SizedBox(height: 16),
                  const Text('正在提交验证...', style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text(
                    '工单号: ${state.workOrder.orderNo}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          } else if (state is SimplePickingSubmitted) {
            return _buildSuccessView(state);
          } else if (state is SimplePickingError) {
            return _buildErrorView(state);
          }
          return const SizedBox();
        },
      ),
    );
  }

  /// 构建订单输入视图
  Widget _buildOrderInputView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.qr_code_scanner,
              size: 100,
              color: Colors.blue,
            ),
            const SizedBox(height: 24),
            const Text(
              '扫描或输入工单号',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            
            // 扫描按钮
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: _startScanning,
                icon: const Icon(Icons.qr_code_scanner, size: 28),
                label: const Text('扫描二维码', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            const Text('或', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 24),
            
            // 手动输入
            TextField(
              controller: _orderNoController,
              style: const TextStyle(fontSize: 20),
              decoration: InputDecoration(
                labelText: '工单号',
                hintText: '请输入工单号',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.edit, size: 28),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _orderNoController.clear(),
                ),
              ),
              onSubmitted: _loadWorkOrder,
            ),
            
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => _loadWorkOrder(_orderNoController.text),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('查询工单', style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建工单视图
  Widget _buildWorkOrderView(SimpleWorkOrder workOrder, bool isModified) {
    // 检查是否为空订单
    final bool isEmptyOrder = workOrder.totalMaterialCount == 0;
    
    // 如果是空订单，显示无需校验提示
    if (isEmptyOrder) {
      return _buildEmptyOrderView(workOrder);
    }
    
    return Column(
      children: [
        // 工单信息卡片
        Container(
          color: Colors.blue.shade50,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '工单号: ${workOrder.orderNo}',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '操作号: ${workOrder.operationNo}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${workOrder.completedMaterialCount}/${workOrder.totalMaterialCount}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: workOrder.isAllCompleted ? Colors.green : Colors.orange,
                        ),
                      ),
                      Text(
                        '${(workOrder.overallProgress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: workOrder.overallProgress,
                minHeight: 10,
                backgroundColor: Colors.grey.shade300,
                valueColor: AlwaysStoppedAnimation<Color>(
                  workOrder.isAllCompleted ? Colors.green : Colors.orange,
                ),
              ),
              // 任务状态提示
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      workOrder.isAllCompleted ? Icons.check_circle : Icons.warning,
                      size: 16,
                      color: workOrder.isAllCompleted ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      workOrder.isAllCompleted ? '所有物料已完成' : '有物料待完成',
                      style: TextStyle(
                        color: workOrder.isAllCompleted ? Colors.green : Colors.orange,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // 物料分类标签页
        Container(
          color: Theme.of(context).colorScheme.primary,
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 4,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: const TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('断线领料'),
                    const SizedBox(width: 4),
                    _buildTabBadge(workOrder.cableMaterials),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('中央仓库'),
                    const SizedBox(width: 4),
                    _buildTabBadge(workOrder.centerMaterials),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('自动化库'),
                    const SizedBox(width: 4),
                    _buildTabBadge(workOrder.autoMaterials),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // 物料列表
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMaterialList(workOrder.cableMaterials, '断线物料'),
              _buildMaterialList(workOrder.centerMaterials, '中央仓库物料'),
              _buildMaterialList(workOrder.autoMaterials, '自动化仓库物料'),
            ],
          ),
        ),
        
        // 底部操作栏
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade300,
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    context.read<SimplePickingBloc>().add(ResetPickingState());
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('返回', style: TextStyle(fontSize: 18)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: workOrder.isAllCompleted
                      ? () => _submitVerification(context)
                      : null,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    backgroundColor: workOrder.isAllCompleted 
                        ? Colors.green 
                        : Colors.grey.shade400,
                    disabledBackgroundColor: Colors.grey.shade400,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!workOrder.isAllCompleted)
                        const Icon(
                          Icons.block,
                          color: Colors.white,
                          size: 20,
                        ),
                      if (!workOrder.isAllCompleted)
                        const SizedBox(width: 8),
                      Text(
                        workOrder.isAllCompleted ? '提交验证' : '任务未完成',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建物料列表
  Widget _buildMaterialList(List<SimpleMaterial> materials, String category) {
    if (materials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              '$category 暂无物料',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: materials.length,
      itemBuilder: (context, index) {
        final material = materials[index];
        return SimpleMaterialItemWidget(
          material: material,
        );
      },
    );
  }

  /// 构建标签页徽章
  /// 构建空订单视图
  Widget _buildEmptyOrderView(SimpleWorkOrder workOrder) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 120,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              '工单号: ${workOrder.orderNo}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '无需校验',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '该工单没有需要校验的物料',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 48),
            // 灰色禁用的提交按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: Colors.grey.shade300,
                ),
                child: const Text(
                  '无需提交',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBadge(List<SimpleMaterial> materials) {
    final completed = materials.where((m) => m.isCompleted).length;
    final total = materials.length;
    
    if (total == 0) return const SizedBox();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: completed == total ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '$completed/$total',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 构建成功视图
  Widget _buildSuccessView(SimplePickingSubmitted state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              size: 120,
              color: Colors.green,
            ),
            const SizedBox(height: 24),
            const Text(
              '验证提交成功！',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '工单号: ${state.workOrder.orderNo}',
              style: const TextStyle(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              state.message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  context.read<SimplePickingBloc>().add(ResetPickingState());
                },
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('继续下一个工单', style: TextStyle(fontSize: 20)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建错误视图
  Widget _buildErrorView(SimplePickingError state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error,
              size: 100,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 24),
            const Text(
              '操作失败',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              state.message,
              style: const TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (state.lastWorkOrder != null)
                  ElevatedButton(
                    onPressed: () {
                      context.read<SimplePickingBloc>().add(
                        LoadWorkOrder(state.lastWorkOrder!.orderNo),
                      );
                    },
                    child: const Text('重试', style: TextStyle(fontSize: 18)),
                  ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: () {
                    context.read<SimplePickingBloc>().add(ResetPickingState());
                  },
                  child: const Text('返回', style: TextStyle(fontSize: 18)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 开始扫描
  void _startScanning() {
    // setState(() => _isScanning = true); // Removed unused state
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            AppBar(
              title: const Text('扫描工单二维码'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
            Expanded(
              child: MobileScanner(
                onDetect: (capture) {
                  final List<Barcode> barcodes = capture.barcodes;
                  for (final barcode in barcodes) {
                    if (barcode.rawValue != null) {
                      Navigator.pop(context);
                      _loadWorkOrder(barcode.rawValue!);
                      break;
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 加载工单
  void _loadWorkOrder(String orderNo) {
    if (orderNo.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入工单号'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    context.read<SimplePickingBloc>().add(LoadWorkOrder(orderNo.trim()));
  }

  /// 提交验证
  void _submitVerification(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认提交'),
        content: const Text('确认所有物料已完成验证并提交？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<SimplePickingBloc>().add(
                const SubmitVerification(
                  updateBy: 'operator', // TODO: 从用户登录信息获取
                  workCenter: 'WC001',  // TODO: 从配置获取
                ),
              );
            },
            child: const Text('确认提交'),
          ),
        ],
      ),
    );
  }
}