import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'seller_drawer.dart';

class SellerHomeScreen extends StatelessWidget {
  const SellerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const SellerDrawer(),
      backgroundColor: Colors.white,
      body: Builder(
        // <-- FIX: Creates correct context for opening drawer
        builder: (context) {
          return Column(
            children: [
              // Purple header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 40,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.lavenderDark,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(10),
                    bottomRight: Radius.circular(10),
                  ),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Scaffold.of(context).openDrawer(); // <-- NOW WORKS
                      },
                      child: const Icon(
                        Icons.menu,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 20),
                    const Text(
                      "Welcome, Seller",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(child: Container(color: Colors.white)),
            ],
          );
        },
      ),
    );
  }
}
