import 'package:flutter/material.dart';
import '../../domain/entities/material_item.dart' as domain;
import '../../../../core/theme/material_status_theme.dart';
import 'material_item_widget.dart';

/// 物料分类区块组件 - 支持展开/折叠和完成状态追踪
class MaterialCategorySection extends StatefulWidget {
  final domain.MaterialCategory category;
  final List<domain.MaterialItem> materials;
  final Function(domain.MaterialItem) onMaterialTap;
  final bool initiallyExpanded;

  const MaterialCategorySection({
    Key? key,
    required this.category,
    required this.materials,
    required this.onMaterialTap,
    this.initiallyExpanded = true,
  }) : super(key: key);

  @override
  State<MaterialCategorySection> createState() => _MaterialCategorySectionState();
}

class _MaterialCategorySectionState extends State<MaterialCategorySection> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _animationController = AnimationController(
      duration: MaterialStatusTheme.expandAnimationDuration,
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  /// 计算完成状态统计
  Map<String, dynamic> _calculateCompletionStats() {
    final completedCount = widget.materials
        .where((m) => m.status == domain.MaterialStatus.completed)
        .length;
    final totalCount = widget.materials.length;
    final percentage = totalCount > 0 ? (completedCount / totalCount * 100) : 0;
    
    return {
      'completed': completedCount,
      'total': totalCount,
      'percentage': percentage.round(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final stats = _calculateCompletionStats();
    final isFullyCompleted = stats['completed'] == stats['total'] && stats['total'] > 0;
    final headerColor = isFullyCompleted ? Colors.green.shade700 : Colors.blue.shade700;
    final headerBgColor = isFullyCompleted ? Colors.green.shade50 : Colors.blue.shade50;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: headerColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // 分类标题栏
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              padding: MaterialStatusTheme.sectionPadding,
              decoration: BoxDecoration(
                color: headerBgColor,
                borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(12),
                  bottom: Radius.circular(_isExpanded ? 0 : 12),
                ),
              ),
              child: Row(
                children: [
                  // 展开/折叠图标
                  AnimatedRotation(
                    turns: _isExpanded ? 0.25 : 0,
                    duration: MaterialStatusTheme.expandAnimationDuration,
                    child: Icon(
                      Icons.chevron_right,
                      size: 28,
                      color: headerColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  
                  // 分类名称
                  Expanded(
                    child: Text(
                      widget.category.label,
                      style: MaterialStatusTheme.titleStyle.copyWith(
                        color: headerColor,
                      ),
                    ),
                  ),
                  
                  // 完成状态统计
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: headerColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: headerColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isFullyCompleted)
                          Icon(
                            Icons.check_circle,
                            size: 18,
                            color: headerColor,
                          )
                        else
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  value: stats['percentage'] / 100,
                                  strokeWidth: 2.5,
                                  backgroundColor: headerColor.withValues(alpha: 0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(headerColor),
                                ),
                              ),
                            ],
                          ),
                        const SizedBox(width: 6),
                        Text(
                          '${stats['completed']}/${stats['total']} 完成',
                          style: MaterialStatusTheme.bodyMediumStyle.copyWith(
                            color: headerColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // 物料列表（可展开/折叠）
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Column(
              children: [
                if (widget.materials.isEmpty)
                  Container(
                    padding: MaterialStatusTheme.sectionPadding,
                    child: Center(
                      child: Text(
                        '该分类暂无物料',
                        style: MaterialStatusTheme.bodyMediumStyle.copyWith(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  ...widget.materials.map((material) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: MaterialItemWidget(
                      material: material,
                      onTap: () => widget.onMaterialTap(material),
                      showInteractiveElements: true,
                    ),
                  )).toList(),
                  
                // 分类底部间距
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 整体完成进度指示器组件
class OverallCompletionIndicator extends StatelessWidget {
  final List<domain.MaterialItem> allMaterials;

  const OverallCompletionIndicator({
    Key? key,
    required this.allMaterials,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final completedCount = allMaterials
        .where((m) => m.status == domain.MaterialStatus.completed)
        .length;
    final totalCount = allMaterials.length;
    final percentage = totalCount > 0 ? (completedCount / totalCount * 100) : 0;
    final isFullyCompleted = completedCount == totalCount && totalCount > 0;
    
    final progressColor = isFullyCompleted ? Colors.green : Colors.blue;
    
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '整体完成进度',
                style: MaterialStatusTheme.bodyLargeStyle.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: progressColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$percentage%',
                  style: MaterialStatusTheme.bodyLargeStyle.copyWith(
                    color: progressColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // 进度条
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage / 100,
              minHeight: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
          const SizedBox(height: 8),
          
          // 统计文字
          Text(
            '$completedCount / $totalCount 物料已完成',
            style: MaterialStatusTheme.bodyMediumStyle.copyWith(
              color: Colors.grey.shade700,
            ),
          ),
          
          // 完成提示
          if (isFullyCompleted)
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.green.shade300,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '所有物料已完成验证，可以提交',
                    style: MaterialStatusTheme.bodyMediumStyle.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
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