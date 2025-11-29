import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/colors.dart';

class SellerProfileScreen extends StatefulWidget {
  const SellerProfileScreen({super.key});

  @override
  State<SellerProfileScreen> createState() => _SellerProfileScreenState();
}

class _SellerProfileScreenState extends State<SellerProfileScreen> {
  // Seller details
  String name = "",
      email = "",
      cnic = "",
      bankName = "",
      bankAccount = "",
      shopName = "";
  String? imageUrl;

  bool loading = true;
  bool updating = false;
  bool isEditing = false;

  File? selectedImage;
  final ImagePicker picker = ImagePicker();

  // Controllers
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController cnicController = TextEditingController();
  final TextEditingController bankNameController = TextEditingController();
  final TextEditingController bankAccountController = TextEditingController();
  final TextEditingController shopNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSellerDetails();
  }

  Future<void> _loadSellerDetails() async {
    setState(() => loading = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("userId");
    if (userId == null) {
      setState(() => loading = false);
      return;
    }

    try {
      final response = await http.get(
        Uri.parse("http://192.168.1.7:3000/get-seller/$userId"),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          name = data["name"] ?? "";
          email = data["email"] ?? "";
          cnic = data["cnic"] ?? "";
          bankName = data["bankName"] ?? "";
          bankAccount = data["bankAccount"] ?? "";
          shopName = data["shopName"] ?? "";
          imageUrl = data["imageUrl"];

          nameController.text = name;
          emailController.text = email;
          cnicController.text = cnic;
          bankNameController.text = bankName;
          bankAccountController.text = bankAccount;
          shopNameController.text = shopName;
          loading = false;
        });
      } else {
        setState(() => loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Failed to load profile")));
      }
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error loading profile: $e")));
    }
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => selectedImage = File(picked.path));
  }

  Future<void> _updateProfile() async {
    setState(() => updating = true);
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userId = prefs.getString("userId");
    if (userId == null) return;

    try {
      var request = http.MultipartRequest(
        "PUT",
        Uri.parse("http://192.168.1.7:3000/update-seller/$userId"),
      );

      request.fields.addAll({
        "name": nameController.text.trim(),
        "email": emailController.text.trim(),
        "cnic": cnicController.text.trim(),
        "bankName": bankNameController.text.trim(),
        "bankAccount": bankAccountController.text.trim(),
        "shopName": shopNameController.text.trim(),
      });

      if (selectedImage != null) {
        request.files.add(
          await http.MultipartFile.fromPath("image", selectedImage!.path),
        );
      }

      var response = await http.Response.fromStream(await request.send());
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile updated successfully")),
        );
        setState(() => isEditing = false);
        _loadSellerDetails();
      } else {
        final data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Update failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
    setState(() => updating = false);
  }

  Widget _detailField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Shop"),
        backgroundColor: AppColors.lavenderDark,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: isEditing ? _pickImage : null,
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: AppColors.lavenderLight,
                      backgroundImage: selectedImage != null
                          ? FileImage(selectedImage!)
                          : (imageUrl != null
                                    ? NetworkImage(
                                        "http://192.168.1.7:3000$imageUrl",
                                      )
                                    : null)
                                as ImageProvider?,
                      child: selectedImage == null && imageUrl == null
                          ? const Icon(
                              Icons.store,
                              size: 60,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 25),
                  isEditing
                      ? Column(
                          children: [
                            _detailField("Shop Name", shopNameController),
                            _detailField("Owner Name", nameController),
                            _detailField("Email", emailController),
                            _detailField("CNIC", cnicController),
                            _detailField("Bank Name", bankNameController),
                            _detailField("Bank Account", bankAccountController),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: updating ? null : _updateProfile,
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  backgroundColor: AppColors.lavenderDark,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: updating
                                    ? const CircularProgressIndicator(
                                        color: Colors.white,
                                      )
                                    : const Text(
                                        "Update Profile",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _profileRow("Shop Name", shopName),
                            _profileRow("Owner Name", name),
                            _profileRow("Email", email),
                            _profileRow("CNIC", cnic),
                            _profileRow("Bank Name", bankName),
                            _profileRow("Bank Account", bankAccount),
                            const SizedBox(height: 30),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () =>
                                    setState(() => isEditing = true),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                  backgroundColor: AppColors.lavenderDark,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  "Edit Profile",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
    );
  }
}
