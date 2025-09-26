import 'package:flutter/material.dart';

class VerificationResultWidget extends StatelessWidget {
  final bool isSuccess;
  final String message;
  final String? scannedOrderId;
  final String expectedOrderId;

  const VerificationResultWidget({
    super.key,
    required this.isSuccess,
    required this.message,
    this.scannedOrderId,
    required this.expectedOrderId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: isSuccess ? Colors.green.shade50 : Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Result icon
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              size: 64,
              color: isSuccess ? Colors.green : Colors.red,
            ),
            
            const SizedBox(height: 16),
            
            // Result message
            Text(
              message,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isSuccess ? Colors.green.shade700 : Colors.red.shade700,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 20),
            
            // Order details
            if (scannedOrderId != null) ...[
              _buildOrderRow('扫描结果:', scannedOrderId!),
              const SizedBox(height: 12),
            ],
            _buildOrderRow('期望订单号:', expectedOrderId),
            
            if (!isSuccess && scannedOrderId != null && scannedOrderId != expectedOrderId) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning, color: Colors.amber, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '订单号不匹配，请检查是否选择了正确的任务',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.amber,
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
    );
  }

  Widget _buildOrderRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ),
      ],
    );
  }
}