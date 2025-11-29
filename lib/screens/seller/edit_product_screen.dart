import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/colors.dart';

class EditProductScreen extends StatefulWidget {
  final Map product;

  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController priceController;

  String? selectedCategory;
  File? selectedImage;
  bool loading = false;

  final List<String> categories = [
    "Bracelet",
    "Ring",
    "Necklace",
    "Earrings",
    "Anklet",
    "Custom",
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.product["productName"] ?? "",
    );
    descriptionController = TextEditingController(
      text: widget.product["description"] ?? "",
    );
    priceController = TextEditingController(
      text: widget.product["price"]?.toString() ?? "",
    );
    selectedCategory = widget.product["category"];
  }

  Future pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        selectedImage = File(picked.path);
      });
    }
  }

  Future<void> updateProduct() async {
    setState(() => loading = true);

    var request = http.MultipartRequest(
      "PUT",
      Uri.parse(
        "http://192.168.1.7:3000/update-product/${widget.product['_id']}",
      ),
    );

    request.fields["productName"] = nameController.text.trim();
    request.fields["description"] = descriptionController.text.trim();
    request.fields["category"] = selectedCategory ?? "";
    request.fields["price"] = priceController.text.trim();

    if (selectedImage != null) {
      request.files.add(
        await http.MultipartFile.fromPath("image", selectedImage!.path),
      );
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Product updated successfully")),
        );
        Navigator.pop(context, true); // return true to refresh list
      } else {
        var data = jsonDecode(response.body);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(data["message"] ?? "Error")));
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
      appBar: AppBar(
        title: const Text("Edit Product"),
        backgroundColor: AppColors.lavenderDark,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            label("Product Image"),
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.lavenderLight.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.file(selectedImage!, fit: BoxFit.cover),
                      )
                    : widget.product["imageUrl"] != null &&
                          widget.product["imageUrl"].toString().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          "http://192.168.1.7:3000${widget.product["imageUrl"]}",
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.add, color: Colors.grey, size: 35),
                      ),
              ),
            ),
            const SizedBox(height: 20),
            label("Product Name"),
            inputField(nameController),
            const SizedBox(height: 20),
            label("Description"),
            inputField(descriptionController),
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
                hint: const Text("Choose a Category"),
                items: categories
                    .map(
                      (cat) => DropdownMenuItem(value: cat, child: Text(cat)),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    selectedCategory = v;
                  });
                },
              ),
            ),
            const SizedBox(height: 20),
            label("Price"),
            inputField(priceController, keyboardType: TextInputType.number),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: loading ? null : updateProduct,
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
                        "Update Product",
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
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
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
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.black26),
        ),
      ),
    );
  }
}
