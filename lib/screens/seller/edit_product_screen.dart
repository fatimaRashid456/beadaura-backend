import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/colors.dart';

// Model to store color and its image
class ColorVariant {
  String color;
  File? image;
  String? imageUrl; // store existing image URL

  ColorVariant({required this.color, this.image, this.imageUrl});
}

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
  late TextEditingController stockController;
  late TextEditingController highlightsController;
  late TextEditingController skuController;
  late TextEditingController sizeController;
  late TextEditingController materialController;

  String? selectedCategory;
  bool loading = false;

  final List<String> categories = [
    "Bracelet",
    "Ring",
    "Necklace",
    "Earrings",
    "Anklet",
    "Custom",
  ];

  // Color variants list
  List<ColorVariant> variants = [];

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
    stockController = TextEditingController(
      text: widget.product["stock"]?.toString() ?? "",
    );
    highlightsController = TextEditingController(
      text: widget.product["highlights"] ?? "",
    );
    skuController = TextEditingController(text: widget.product["sku"] ?? "");
    sizeController = TextEditingController(text: widget.product["size"] ?? "");
    materialController = TextEditingController(
      text: widget.product["material"] ?? "",
    );
    selectedCategory = widget.product["category"];

    // Initialize color variants
    if (widget.product["variants"] != null &&
        widget.product["variants"] is List) {
      for (var variant in widget.product["variants"]) {
        variants.add(
          ColorVariant(
            color: variant["color"] ?? '',
            imageUrl: variant["imageUrl"],
          ),
        );
      }
    } else {
      variants.add(ColorVariant(color: '', imageUrl: null));
    }
  }

  Future pickImage(int index) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        variants[index].image = File(picked.path);
        variants[index].imageUrl = null; // clear old imageUrl when picking new
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

    request.fields.addAll({
      "productName": nameController.text.trim(),
      "description": descriptionController.text.trim(),
      "category": selectedCategory ?? "",
      "price": priceController.text.trim(),
      "stock": stockController.text.trim(),
      "highlights": highlightsController.text.trim(),
      "sku": skuController.text.trim(),
      "size": sizeController.text.trim(),
      "material": materialController.text.trim(),
    });

    // Add color variants
    for (int i = 0; i < variants.length; i++) {
      request.fields['colors[$i]'] = variants[i].color;
      if (variants[i].image != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'images', // backend expects 'images'
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
            label("Product Name"),
            inputField(nameController),
            const SizedBox(height: 20),
            label("Description"),
            inputField(descriptionController, maxLines: 5),
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
            const SizedBox(height: 20),
            label("Stock"),
            inputField(stockController, keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            label("Highlights"),
            inputField(highlightsController),
            const SizedBox(height: 20),
            label("SKU"),
            inputField(skuController),
            const SizedBox(height: 20),
            label("Size"),
            inputField(sizeController),
            const SizedBox(height: 20),
            label("Material"),
            inputField(materialController),
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
                              : variant.imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(
                                    "http://192.168.1.7:3000${variant.imageUrl}",
                                  ),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: variant.image == null && variant.imageUrl == null
                            ? const Icon(Icons.add, color: Colors.grey)
                            : null,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            TextButton.icon(
              onPressed: () => setState(
                () => variants.add(ColorVariant(color: '', imageUrl: null)),
              ),
              icon: const Icon(Icons.add),
              label: const Text("Add Color Variant"),
            ),
            const SizedBox(height: 30),
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
    int maxLines = 1,
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
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.black26),
        ),
      ),
    );
  }
}
