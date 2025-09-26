import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/material_item.dart' as domain;
import '../../domain/entities/picking_order.dart';
import '../bloc/picking_verification_bloc.dart';
import '../bloc/picking_verification_event.dart';
import 'material_category_section.dart';
import 'status_update_dialog.dart';

/// 物料清单组件 - 增强版支持状态管理和交互
/// 按类别分组显示物料项，支持展开/折叠和状态更新
class MaterialListWidget extends StatelessWidget {
  final PickingOrder order;
  final bool isPortrait;

  const MaterialListWidget({
    Key? key,
    required this.order,
    this.isPortrait = true,
  }) : super(key: key);

  void _handleMaterialTap(BuildContext context, domain.MaterialItem material) {
    // Show status update dialog
    StatusUpdateDialog.show(
      context: context,
      material: material,
      onStatusSelected: (newStatus) {
        // Dispatch update event to BLoC
        context.read<PickingVerificationBloc>().add(
          UpdateMaterialStatus(
            materialId: material.id,
            newStatus: newStatus,
            previousStatus: material.status,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final materialsByCategory = order.materialsByCategory;
    
    if (order.materials.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '暂无物料信息',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Build responsive layout
    if (!isPortrait) {
      // Landscape mode - side-by-side layout
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall completion on the left
          Container(
            width: 300,
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                OverallCompletionIndicator(
                  allMaterials: order.materials,
                ),
                const SizedBox(height: 16),
                // Add action buttons here if needed
              ],
            ),
          ),
          // Material categories on the right
          Expanded(
            child: _buildCategorySections(context, materialsByCategory),
          ),
        ],
      );
    }

    // Portrait mode - vertical layout
    return Column(
      children: [
        // Overall completion at the top
        OverallCompletionIndicator(
          allMaterials: order.materials,
        ),
        // Material categories below
        Expanded(
          child: _buildCategorySections(context, materialsByCategory),
        ),
      ],
    );
  }

  Widget _buildCategorySections(
    BuildContext context,
    Map<domain.MaterialCategory, List<domain.MaterialItem>> materialsByCategory,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      itemCount: materialsByCategory.length,
      itemBuilder: (context, index) {
        final category = materialsByCategory.keys.elementAt(index);
        final materials = materialsByCategory[category]!;
        
        return MaterialCategorySection(
          category: category,
          materials: materials,
          onMaterialTap: (material) => _handleMaterialTap(context, material),
          initiallyExpanded: true,
        );
      },
    );
  }
}