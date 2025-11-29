import 'package:flutter/material.dart';
import 'add_product_screen.dart';
import 'my_products_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'seller_profile_screen.dart';

class SellerDrawer extends StatelessWidget {
  const SellerDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 260,
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 60),

            // Flower logo (your image)
            Center(child: Image.asset("assets/flower.png", height: 120)),

            const SizedBox(height: 10),

            // Shop name
            const Center(
              child: Text(
                "Bead Aura",
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFFBB11DE),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 30),

            drawerTile("Add Product", () {
              Navigator.pop(context); // close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddProductScreen()),
              );
            }),
            drawerTile("My Products", () {
              Navigator.pop(context); // close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MyProductsScreen()),
              );
            }),

            drawerTile("My Shop", () {
              Navigator.pop(context); // close drawer
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SellerProfileScreen()),
              );
            }),
            drawerTile("Orders Received", () {}),
            drawerTile("Earnings / Stats", () {}),
            drawerTile("Logout", () async {
              Navigator.pop(context); // close drawer

              // Clear stored user info
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs
                  .clear(); // clears all saved data (like userId, email, role, etc.)

              // Navigate to login screen and remove all previous routes
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget drawerTile(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: GestureDetector(
        onTap: onTap,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: Color.fromARGB(221, 71, 71, 71),
          ),
        ),
      ),
    );
  }
}
