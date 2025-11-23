import 'package:flutter/material.dart';
import '../utils/colors.dart';
import 'otp_verify_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  TextEditingController emailController = TextEditingController();
  bool loading = false;

  Future<void> sendOtp() async {
    setState(() => loading = true);

    try {
      var response = await http.post(
        Uri.parse("http://localhost:3000/send-forgot-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": emailController.text.trim()}),
      );

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                OTPVerifyScreen(email: emailController.text.trim()),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data["message"])));
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
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Column(
          children: [
            const SizedBox(height: 60),
            Align(
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.lavenderDark,
                ),
                onPressed: () {
                  Navigator.pop(context); // Goes back to the previous screen
                },
              ),
            ),

            const SizedBox(height: 40),

            Image.asset("assets/flower.png", height: 150),

            const SizedBox(height: 20),
            const Text(
              "Forgot password?",
              style: TextStyle(
                fontSize: 20,
                color: AppColors.lavenderDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Enter your email below to receive password reset instructions",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 25),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Email Address",
                style: TextStyle(
                  color: AppColors.lavenderDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),

            TextField(
              controller: emailController,
              decoration: InputDecoration(
                hintText: "Enter your email address",
                filled: true,
                fillColor: const Color(0xFFF4F4F4),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : sendOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lavenderDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Submit",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
