import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/line_stock_bloc.dart';
import '../bloc/line_stock_state.dart';

/// Stock Query Screen
/// Allows users to query stock information by barcode
class StockQueryScreen extends StatelessWidget {
  const StockQueryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📦 库存查询'),
      ),
      body: BlocConsumer<LineStockBloc, LineStockState>(
        listener: (context, state) {
          // Handle error states
          if (state is LineStockError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          return const Center(
            child: Text('Stock Query Screen - To be implemented'),
          );
        },
      ),
    );
  }
}
