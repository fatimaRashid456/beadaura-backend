import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/colors.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

// Model to store color and its image
class ColorVariant {
  String color;
  File? image;

  ColorVariant({required this.color, this.image});
}

class _AddProductScreenState extends State<AddProductScreen> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController stockController = TextEditingController();
  final TextEditingController highlightsController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController sizeController = TextEditingController();
  final TextEditingController materialController = TextEditingController();

  bool loading = false;
  String? selectedCategory;

  final List<String> categories = [
    "Bracelet",
    "Ring",
    "Necklace",
    "Earrings",
    "Anklet",
    "Custom",
  ];

  // List of color variants
  List<ColorVariant> variants = [ColorVariant(color: '')];

  // Pick image for a specific variant
  Future<void> pickImage(int index) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);
      if (pickedFile != null) {
        setState(() {
          variants[index].image = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error picking image: $e")));
    }
  }

  // Add product API call
  Future<void> addProduct() async {
    // Validate fields
    if (nameController.text.trim().isEmpty ||
        descriptionController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty ||
        stockController.text.trim().isEmpty ||
        highlightsController.text.trim().isEmpty ||
        skuController.text.trim().isEmpty ||
        sizeController.text.trim().isEmpty ||
        materialController.text.trim().isEmpty ||
        selectedCategory == null ||
        variants.any((v) => v.color.trim().isEmpty || v.image == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields and add color/image"),
        ),
      );
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? sellerId = prefs.getString("userId");
    if (sellerId == null) return;

    setState(() => loading = true);

    var request = http.MultipartRequest(
      "POST",
      Uri.parse("http://beadaura-backend.onrender.com/add-product"),
    );

    // Add basic product info
    request.fields.addAll({
      "sellerId": sellerId,
      "productName": nameController.text.trim(),
      "description": descriptionController.text.trim(),
      "category": selectedCategory!,
      "price": priceController.text.trim(),
      "stock": stockController.text.trim(),
      "highlights": highlightsController.text.trim(),
      "sku": skuController.text.trim(),
      "size": sizeController.text.trim(),
      "material": materialController.text.trim(),
    });

    // Add color variants and images
    for (int i = 0; i < variants.length; i++) {
      request.fields['colors[$i]'] = variants[i].color;
      if (variants[i].image != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images', // backend expects 'images' as the key
            variants[i].image!.path,
          ),
        );
      }
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product added successfully")),
        );
        Navigator.pop(context);
      } else {
        var data = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "Something went wrong")),
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
      backgroundColor: AppColors.white,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.only(
              top: 50,
              left: 15,
              right: 15,
              bottom: 20,
            ),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.lavenderDark, AppColors.lavenderMedium],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(25),
                bottomRight: Radius.circular(25),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  "Add Product",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  label("Product Name"),
                  inputField(nameController, "e.g., Pearl Bracelet"),
                  const SizedBox(height: 20),

                  label("Description"),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: AppColors.lavenderLight.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: descriptionController,
                      maxLines: 8,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: "Enter detailed description (max 250 words)",
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  label("Category"),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: AppColors.lavenderLight.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      underline: const SizedBox(),
                      dropdownColor: Colors.white,
                      hint: const Text(
                        "Choose a Category",
                        style: TextStyle(color: Colors.grey),
                      ),
                      items: categories
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => selectedCategory = v),
                    ),
                  ),
                  const SizedBox(height: 20),

                  label("Price"),
                  inputField(
                    priceController,
                    "Enter price in USD",
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),

                  label("Stock"),
                  inputField(
                    stockController,
                    "Enter stock quantity",
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),

                  label("Highlights"),
                  inputField(
                    highlightsController,
                    "e.g., Handmade, Adjustable Size",
                  ),
                  const SizedBox(height: 20),

                  label("SKU"),
                  inputField(skuController, "Enter unique SKU, e.g., BR-001"),
                  const SizedBox(height: 20),

                  label("Size"),
                  inputField(
                    sizeController,
                    "Enter size (e.g., 7 inches or W10xL5cm)",
                  ),
                  const SizedBox(height: 20),

                  label("Material"),
                  inputField(materialController, "e.g., Pearl, Leather"),
                  const SizedBox(height: 20),

                  label("Color Variants"),
                  ...variants.asMap().entries.map((entry) {
                    int index = entry.key;
                    ColorVariant variant = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: inputField(
                              TextEditingController(text: variant.color),
                              "Enter color",
                              onChanged: (v) => variant.color = v,
                            ),
                          ),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => pickImage(index),
                            child: Container(
                              height: 50,
                              width: 50,
                              decoration: BoxDecoration(
                                color: AppColors.lavenderLight.withOpacity(0.4),
                                borderRadius: BorderRadius.circular(12),
                                image: variant.image != null
                                    ? DecorationImage(
                                        image: FileImage(variant.image!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: variant.image == null
                                  ? const Icon(Icons.add, color: Colors.grey)
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  TextButton.icon(
                    onPressed: () =>
                        setState(() => variants.add(ColorVariant(color: ''))),
                    icon: const Icon(Icons.add),
                    label: const Text("Add Color Variant"),
                  ),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loading ? null : addProduct,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        backgroundColor: AppColors.lavenderDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Add Product",
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
            ),
          ),
        ],
      ),
    );
  }

  Widget label(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.lavenderDark,
      ),
    );
  }

  Widget inputField(
    TextEditingController controller,
    String hintText, {
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: AppColors.lavenderLight.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}
