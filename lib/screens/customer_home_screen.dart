import 'package:flutter/material.dart';
import '../utils/colors.dart';

class CustomerHomeScreen extends StatelessWidget {
  const CustomerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text("Customer Home"),
        backgroundColor: AppColors.white,
        elevation: 0,
        foregroundColor: AppColors.black,
      ),
      body: const Center(
        child: Text('Welcome, Customer!', style: TextStyle(fontSize: 18)),
      ),
    );
  }
}
