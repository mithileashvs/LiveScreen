import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TicketsScreen extends StatelessWidget {
  const TicketsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('My Tickets')),
      body: const Center(
        child: Text('Your bookings will appear here', style: AppTextStyles.body),
      ),
    );
  }
}
