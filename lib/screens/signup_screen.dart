import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/colors.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'seller_home_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  _SignupScreenState createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController cnicController = TextEditingController();
  final TextEditingController bankController = TextEditingController();
  final TextEditingController shopNameController = TextEditingController();

  String role = "customer";
  String selectedBank = "Habib Bank Limited";
  bool loading = false;
  bool _obscurePassword = true;

  final List<String> bankNames = [
    "Habib Bank Limited",
    "MCB Bank",
    "United Bank Limited",
    "Standard Chartered",
    "Allied Bank",
    "Bank Alfalah",
    "Faysal Bank",
    "Askari Bank",
  ];

  // ==================== OTP Popup ====================
  Future<Map<String, dynamic>?> _showOtpDialog(String email) async {
    TextEditingController otpController = TextEditingController();
    return await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool verifying = false;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text("Enter OTP"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(hintText: "6-digit OTP"),
                  ),
                  if (verifying) ...[
                    const SizedBox(height: 10),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: verifying
                      ? null
                      : () async {
                          String otp = otpController.text.trim();
                          if (otp.length != 6) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Enter a valid 6-digit OTP"),
                              ),
                            );
                            return;
                          }

                          setState(() => verifying = true);

                          try {
                            var url = Uri.parse(
                              'http://192.168.1.7:3000/verify-otp',
                            );
                            var response = await http.post(
                              url,
                              headers: {"Content-Type": "application/json"},
                              body: jsonEncode({"email": email, "otp": otp}),
                            );

                            if (response.statusCode == 200) {
                              var userData = jsonDecode(response.body);
                              Navigator.of(context).pop(userData);
                            } else {
                              setState(() => verifying = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Invalid OTP")),
                              );
                            }
                          } catch (e) {
                            setState(() => verifying = false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Error: $e")),
                            );
                          }
                        },
                  child: const Text("Verify"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ==================== Signup ====================
  Future<void> signup() async {
    if (nameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        (role == "seller" &&
            (cnicController.text.trim().isEmpty ||
                bankController.text.trim().isEmpty ||
                shopNameController.text.trim().isEmpty))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    if (role == "seller" &&
        (cnicController.text.trim().length != 13 ||
            !RegExp(r'^[0-9]+$').hasMatch(cnicController.text.trim()))) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("CNIC must be 13 digits")));
      return;
    }

    if (!RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(emailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email")),
      );
      return;
    }

    if (passwordController.text.trim().length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password must be at least 6 characters")),
      );
      return;
    }

    setState(() => loading = true);

    var url = Uri.parse('http://192.168.1.7:3000/signup');
    var bodyData = {
      "name": nameController.text.trim(),
      "email": emailController.text.trim(),
      "password": passwordController.text.trim(),
      "role": role,
    };

    if (role == "seller") {
      bodyData["cnic"] = cnicController.text.trim();
      bodyData["bankAccount"] = bankController.text.trim();
      bodyData["bankName"] = selectedBank;
      bodyData["shopName"] = shopNameController.text.trim();
    }

    try {
      var response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(bodyData),
      );

      if (response.statusCode == 200) {
        var otpResult = await _showOtpDialog(emailController.text.trim());

        if (otpResult != null &&
            otpResult.containsKey("userId") &&
            otpResult.containsKey("role") &&
            otpResult.containsKey("name")) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setBool("isLoggedIn", true);
          await prefs.setString("userId", otpResult["userId"]);
          await prefs.setString("userRole", otpResult["role"]);
          await prefs.setString("userName", otpResult["name"]);

          if (!mounted) return;

          String userRole = otpResult["role"];

          Widget nextScreen;

          if (userRole == "seller") {
            nextScreen =
                const SellerHomeScreen(); // *** send sellers to SellerHomeScreen ***
          } else {
            nextScreen = HomeScreen(); // customers go to HomeScreen
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => nextScreen),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("OTP verification failed")),
          );
        }
      } else {
        var data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Signup failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lavenderLight,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "Sign up to your account",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 25,
                ),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label("Full Name"),
                      _textField(
                        controller: nameController,
                        hint: "Enter your full name",
                      ),
                      const SizedBox(height: 20),
                      _label("Email Address"),
                      _textField(
                        controller: emailController,
                        hint: "Enter your email address",
                      ),
                      const SizedBox(height: 20),
                      _label("Password"),
                      _textField(
                        controller: passwordController,
                        hint: "Enter your password",
                        obscure: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: Colors.grey,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _label("Role"),
                      DropdownButtonFormField<String>(
                        value: role,
                        items: const [
                          DropdownMenuItem(
                            value: "customer",
                            child: Text("Customer"),
                          ),
                          DropdownMenuItem(
                            value: "seller",
                            child: Text("Seller"),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => role = value);
                        },
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 15,
                            vertical: 15,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      if (role == "seller") ...[
                        const SizedBox(height: 20),
                        _label("CNIC"),
                        _textField(
                          controller: cnicController,
                          hint: "Enter CNIC",
                        ),
                        const SizedBox(height: 20),
                        _label("Bank Name"),
                        DropdownButtonFormField<String>(
                          value: selectedBank,
                          items: bankNames
                              .map(
                                (bank) => DropdownMenuItem(
                                  value: bank,
                                  child: Text(bank),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null)
                              setState(() => selectedBank = value);
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 15,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        _label("Bank Account Number"),
                        _textField(
                          controller: bankController,
                          hint: "Enter bank account",
                        ),
                        const SizedBox(height: 20),
                        _label("Shop Name"),
                        _textField(
                          controller: shopNameController,
                          hint: "Enter shop name",
                        ),
                      ],
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: loading ? null : signup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.lavenderDark,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Sign up",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                          },
                          child: const Text.rich(
                            TextSpan(
                              text: "Already have an account? ",
                              children: [
                                TextSpan(
                                  text: "Login",
                                  style: TextStyle(
                                    color: AppColors.lavenderDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) =>
      Text(text, style: TextStyle(color: AppColors.lavenderDark, fontSize: 15));

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,
    Widget? suffixIcon,
  }) => TextField(
    controller: controller,
    obscureText: obscure,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.grey.shade100,
      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      suffixIcon: suffixIcon ?? const SizedBox.shrink(),
    ),
  );
}
