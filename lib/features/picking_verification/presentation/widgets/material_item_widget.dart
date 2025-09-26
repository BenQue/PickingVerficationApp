import 'package:flutter/material.dart';
import '../../domain/entities/material_item.dart';
import '../../../../core/theme/material_status_theme.dart';
import 'material_status_indicator.dart';

/// 单个物料项显示组件 - 增强版本支持状态可视化和交互
class MaterialItemWidget extends StatelessWidget {
  final MaterialItem material;
  final VoidCallback? onTap;
  final bool showInteractiveElements;

  const MaterialItemWidget({
    Key? key,
    required this.material,
    this.onTap,
    this.showInteractiveElements = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusColor = MaterialStatusTheme.getStatusColor(material.status);
    final backgroundColor = MaterialStatusTheme.getStatusBackgroundColor(material.status);
    
    return InkWell(
      onTap: showInteractiveElements ? onTap : null,
      child: Container(
        padding: MaterialStatusTheme.itemPadding,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 增强的状态指示器
            MaterialStatusIndicator(
              status: material.status,
              iconSize: 28,
              showLabel: false,
              compact: true,
            ),
            const SizedBox(width: 12),
            
            // 物料信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 物料名称、编码和状态
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          material.name,
                          style: MaterialStatusTheme.bodyLargeStyle.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // 状态标签
                      MaterialStatusIndicator(
                        status: material.status,
                        iconSize: 16,
                        showLabel: true,
                        compact: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  
                  // 物料描述
                  if (material.description != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        material.description!,
                        style: MaterialStatusTheme.bodyMediumStyle.copyWith(
                          color: Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  
                  // 数量和位置信息
                  Row(
                    children: [
                      // 数量信息
                      _buildQuantityInfo(),
                      const SizedBox(width: 16),
                      
                      // 位置信息
                      Expanded(
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                material.location,
                                style: MaterialStatusTheme.bodyMediumStyle.copyWith(
                                  color: Colors.grey[700],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // 备注信息
                  if (material.remarks != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 14,
                              color: Colors.amber.shade700,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                material.remarks!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // 交互提示图标
            if (showInteractiveElements && onTap != null)
              Container(
                width: MaterialStatusTheme.minTouchTargetSize,
                height: MaterialStatusTheme.minTouchTargetSize,
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.touch_app,
                  size: 24,
                  color: Colors.blue[700],
                ),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildQuantityInfo() {
    final bool isFulfilled = material.isFulfilled;
    final Color quantityColor = isFulfilled ? Colors.green.shade700 : Colors.red.shade700;
    final Color quantityBgColor = isFulfilled ? Colors.green.shade50 : Colors.red.shade50;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: quantityBgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: quantityColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isFulfilled ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            size: 18,
            color: quantityColor,
          ),
          const SizedBox(width: 4),
          Text(
            '${material.availableQuantity}/${material.requiredQuantity}',
            style: MaterialStatusTheme.bodyLargeStyle.copyWith(
              fontWeight: FontWeight.w700,
              color: quantityColor,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            material.unit,
            style: MaterialStatusTheme.bodyMediumStyle.copyWith(
              color: quantityColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}