import 'package:flutter/material.dart';
import '../../domain/entities/task.dart';

class TaskItemWidget extends StatelessWidget {
  const TaskItemWidget({
    super.key,
    required this.task,
    required this.onTap,
  });

  final Task task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 8,
                height: 60,
                decoration: BoxDecoration(
                  color: _getStatusColor(task.status),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 16),
              // Task info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Order number
                    Text(
                      '订单号: ${task.orderNumber}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                    ),
                    const SizedBox(height: 8),
                    // Task type and status
                    Row(
                      children: [
                        _buildChip(
                          context,
                          task.type.displayName,
                          _getTypeColor(task.type),
                        ),
                        const SizedBox(width: 8),
                        _buildChip(
                          context,
                          task.status.displayName,
                          _getStatusColor(task.status),
                        ),
                      ],
                    ),
                    // Priority and due date if available
                    if (task.priority != null || task.dueDate != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (task.priority != null) ...[
                            Icon(
                              _getPriorityIcon(task.priority!),
                              size: 16,
                              color: _getPriorityColor(task.priority!),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _getPriorityText(task.priority!),
                              style: TextStyle(
                                fontSize: 12,
                                color: _getPriorityColor(task.priority!),
                              ),
                            ),
                          ],
                          if (task.priority != null && task.dueDate != null)
                            const SizedBox(width: 16),
                          if (task.dueDate != null) ...[
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(task.dueDate!),
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow indicator
              const Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _getStatusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.pending:
        return Colors.orange;
      case TaskStatus.inProgress:
        return Colors.blue;
      case TaskStatus.completed:
        return Colors.green;
      case TaskStatus.cancelled:
        return Colors.red;
    }
  }

  Color _getTypeColor(TaskType type) {
    switch (type) {
      case TaskType.pickingVerification:
        return Colors.purple;
      case TaskType.platformReceiving:
        return Colors.teal;
      case TaskType.lineDelivery:
        return Colors.indigo;
    }
  }

  IconData _getPriorityIcon(int priority) {
    if (priority >= 3) return Icons.flag;
    if (priority >= 2) return Icons.flag_outlined;
    return Icons.outlined_flag;
  }

  Color _getPriorityColor(int priority) {
    if (priority >= 3) return Colors.red;
    if (priority >= 2) return Colors.orange;
    return Colors.grey;
  }

  String _getPriorityText(int priority) {
    if (priority >= 3) return '高优先级';
    if (priority >= 2) return '中优先级';
    return '低优先级';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}