import 'package:flutter/material.dart';
import '../../domain/entities/material_item.dart' as domain;
import '../../../../core/theme/material_status_theme.dart';
import 'material_status_indicator.dart';

/// 状态选择对话框
class StatusUpdateDialog extends StatefulWidget {
  final domain.MaterialItem material;
  final domain.MaterialStatus currentStatus;
  final Function(domain.MaterialStatus) onStatusSelected;

  const StatusUpdateDialog({
    Key? key,
    required this.material,
    required this.currentStatus,
    required this.onStatusSelected,
  }) : super(key: key);

  static Future<void> show({
    required BuildContext context,
    required domain.MaterialItem material,
    required Function(domain.MaterialStatus) onStatusSelected,
  }) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatusUpdateDialog(
        material: material,
        currentStatus: material.status,
        onStatusSelected: onStatusSelected,
      ),
    );
  }

  @override
  State<StatusUpdateDialog> createState() => _StatusUpdateDialogState();
}

class _StatusUpdateDialogState extends State<StatusUpdateDialog> {
  late domain.MaterialStatus _selectedStatus;
  
  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.currentStatus;
  }

  void _handleConfirm() {
    // 如果状态改变了，显示确认对话框
    if (_selectedStatus != widget.currentStatus) {
      _showConfirmationDialog();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _showConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.orange.shade700,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Text('确认状态更改'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '物料: ${widget.material.name}',
              style: MaterialStatusTheme.bodyLargeStyle.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('当前状态: '),
                MaterialStatusIndicator(
                  status: widget.currentStatus,
                  iconSize: 16,
                  showLabel: true,
                  compact: false,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('新状态: '),
                MaterialStatusIndicator(
                  status: _selectedStatus,
                  iconSize: 16,
                  showLabel: true,
                  compact: false,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '确认要将状态更改为 "${MaterialStatusTheme.getStatusText(_selectedStatus)}" 吗？',
              style: MaterialStatusTheme.bodyMediumStyle,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '取消',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              '确认更改',
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      widget.onStatusSelected(_selectedStatus);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.all(20),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 对话框标题
            Container(
              padding: MaterialStatusTheme.sectionPadding,
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    size: 28,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '更新物料状态',
                          style: MaterialStatusTheme.titleStyle.copyWith(
                            color: Colors.blue.shade700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.material.name,
                          style: MaterialStatusTheme.bodyMediumStyle.copyWith(
                            color: Colors.blue.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // 状态选项列表
            Flexible(
              child: SingleChildScrollView(
                padding: MaterialStatusTheme.sectionPadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '选择新状态:',
                      style: MaterialStatusTheme.bodyLargeStyle.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // 状态选项
                    ...domain.MaterialStatus.values.map((status) {
                      final isSelected = _selectedStatus == status;
                      final statusColor = MaterialStatusTheme.getStatusColor(status);
                      final bgColor = MaterialStatusTheme.getStatusBackgroundColor(status);
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              _selectedStatus = status;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: MaterialStatusTheme.statusChangeAnimationDuration,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? bgColor : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected 
                                    ? statusColor 
                                    : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                // 选择指示器
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected 
                                          ? statusColor 
                                          : Colors.grey.shade400,
                                      width: 2,
                                    ),
                                    color: isSelected 
                                        ? statusColor 
                                        : Colors.transparent,
                                  ),
                                  child: isSelected
                                      ? const Icon(
                                          Icons.check,
                                          size: 16,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 12),
                                
                                // 状态指示器
                                Expanded(
                                  child: MaterialStatusIndicator(
                                    status: status,
                                    iconSize: 24,
                                    showLabel: true,
                                    compact: false,
                                  ),
                                ),
                                
                                // 当前状态标记
                                if (status == widget.currentStatus)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '当前',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            
            // 操作按钮
            Container(
              padding: MaterialStatusTheme.sectionPadding,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      minimumSize: Size(MaterialStatusTheme.minTouchTargetSize * 2,
                          MaterialStatusTheme.minTouchTargetSize),
                    ),
                    child: Text(
                      '取消',
                      style: MaterialStatusTheme.bodyLargeStyle.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _handleConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      minimumSize: Size(MaterialStatusTheme.minTouchTargetSize * 2,
                          MaterialStatusTheme.minTouchTargetSize),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      '确定',
                      style: MaterialStatusTheme.bodyLargeStyle.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}