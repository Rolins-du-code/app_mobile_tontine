import 'package:flutter/material.dart';
import '../../core/theme.dart';

class DashboardTontineScreen extends StatelessWidget {
  final String tontineId;
  final String role;

  const DashboardTontineScreen({
    super.key,
    required this.tontineId,
    required this.role,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: const Center(
        child: Text('Dashboard — bientôt'),
      ),
    );
  }
}