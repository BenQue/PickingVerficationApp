import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/line_stock_bloc.dart';
import '../bloc/line_stock_event.dart';
import '../bloc/line_stock_state.dart';

/// Cable Shelving Screen
/// Allows users to transfer cables to target location
class CableShelvingScreen extends StatelessWidget {
  const CableShelvingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📤 电缆上架'),
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
          // Handle success states
          if (state is ShelvingSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.displayMessage),
                backgroundColor: Colors.green,
              ),
            );
            // Reset after success
            context.read<LineStockBloc>().add(const ResetShelving());
          }
        },
        builder: (context, state) {
          return const Center(
            child: Text('Cable Shelving Screen - To be implemented'),
          );
        },
      ),
    );
  }
}
