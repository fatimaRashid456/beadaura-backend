import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/colors.dart';
import 'reset_password_screen.dart';

class OTPVerifyScreen extends StatefulWidget {
  final String email;
  const OTPVerifyScreen({super.key, required this.email});

  @override
  State<OTPVerifyScreen> createState() => _OTPVerifyScreenState();
}

class _OTPVerifyScreenState extends State<OTPVerifyScreen> {
  List<TextEditingController> otpControllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  List<FocusNode> otpFocusNodes = List.generate(6, (index) => FocusNode());

  bool loading = false;

  @override
  void dispose() {
    for (var controller in otpControllers) controller.dispose();
    for (var node in otpFocusNodes) node.dispose();
    super.dispose();
  }

  Future<void> verifyOtp() async {
    setState(() => loading = true);

    String otp = otpControllers.map((c) => c.text).join("");

    try {
      var response = await http.post(
        Uri.parse("http://beadaura-backend.onrender.com/verify-forgot-otp"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": widget.email, "otp": otp}),
      );

      var data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(email: widget.email),
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
            const Text(
              "Check Your Email\nVerify OTP Now",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                color: AppColors.lavenderDark,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text("Enter a 6-digit code sent to you"),
            const SizedBox(height: 25),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(
                6,
                (index) => SizedBox(
                  width: 45,
                  child: TextField(
                    controller: otpControllers[index],
                    focusNode: otpFocusNodes[index],
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      counterText: "",
                      filled: true,
                      fillColor: Color(0xFFF4F4F4),
                    ),
                    onChanged: (value) {
                      if (value.isNotEmpty && index < 5) {
                        // Move focus to next box
                        FocusScope.of(
                          context,
                        ).requestFocus(otpFocusNodes[index + 1]);
                      } else if (value.isEmpty && index > 0) {
                        // If deleted, move back
                        FocusScope.of(
                          context,
                        ).requestFocus(otpFocusNodes[index - 1]);
                      }
                    },
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: loading ? null : verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.lavenderDark,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Verify",
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
