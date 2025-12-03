import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../utils/colors.dart';
import 'store_products_screen.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Map<String, dynamic>? store;
  bool storeLoading = true;
  int _currentImageIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    fetchStore();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> fetchStore() async {
    final sellerId = widget.product['sellerId'];
    if (sellerId == null) {
      setState(() => storeLoading = false);
      return;
    }

    try {
      final url = Uri.parse(
        'http://beadaura-backend.onrender.com/get-seller/$sellerId',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          store = {
            '_id': sellerId,
            'name': data['shopName'] ?? data['name'] ?? 'Store',
          };
          storeLoading = false;
        });
      } else {
        setState(() => storeLoading = false);
      }
    } catch (e) {
      setState(() => storeLoading = false);
    }
  }

  Color parseColor(String? colorString) {
    if (colorString == null) return AppColors.lavenderDark;
    String hex = colorString.replaceAll('#', '').trim();
    if (hex.length == 6) hex = 'FF$hex';
    try {
      return Color(int.parse('0x$hex'));
    } catch (_) {
      return AppColors.lavenderDark;
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final variants = product['variants'] ?? [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.lavenderMedium,
        title: Text(
          product['productName'] ?? "Product",
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 80),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // IMAGE CAROUSEL
                SizedBox(
                  height: 300,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: variants.length,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      String imageUrl = variants[index]['imageUrl'] ?? '';
                      if (imageUrl.startsWith("/uploads")) {
                        imageUrl = "beadaura-backend.onrender.com$imageUrl";
                      }
                      return imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) =>
                                  progress == null
                                  ? child
                                  : const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey,
                                child: const Icon(Icons.image, size: 50),
                              ),
                            )
                          : Container(
                              color: Colors.grey,
                              child: const Icon(Icons.image, size: 50),
                            );
                    },
                  ),
                ),

                // IMAGE INDICATOR DOTS
                if (variants.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(variants.length, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        width: _currentImageIndex == index ? 12 : 8,
                        height: _currentImageIndex == index ? 12 : 8,
                        decoration: BoxDecoration(
                          color: _currentImageIndex == index
                              ? AppColors.lavenderDark
                              : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),

                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Name
                      Text(
                        product['productName'] ?? '',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),

                      // Highlights - stylish font
                      if ((product['highlights'] ?? '').toString().isNotEmpty)
                        Text(
                          product['highlights'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.normal,
                            fontWeight: FontWeight.w500,
                            color: AppColors.lavenderDark,
                          ),
                        ),
                      const SizedBox(height: 6),

                      // Material info
                      if ((product['material'] ?? '').toString().isNotEmpty)
                        Text(
                          "Material: ${product['material']}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      const SizedBox(height: 4),

                      // Size info
                      if ((product['size'] ?? '').toString().isNotEmpty)
                        Text(
                          "Size: ${product['size']}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                      const SizedBox(height: 8),

                      // Price
                      Text(
                        "Price: ₹${product['price'] ?? ''}",
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.lavenderDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Color boxes with text
                      if (variants.isNotEmpty) ...[
                        const Text(
                          "Variants:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: variants.length,
                            itemBuilder: (context, index) {
                              Color color = parseColor(
                                variants[index]['color']?.toString(),
                              );
                              String colorName =
                                  variants[index]['color'] ?? 'Color';

                              // Light background for the box
                              Color backgroundColor = color.withOpacity(0.2);

                              // Text color based on brightness
                              Color textColor = color.computeLuminance() > 0.5
                                  ? const Color.fromARGB(255, 255, 255, 255)
                                  : const Color.fromARGB(255, 255, 255, 255);

                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _currentImageIndex = index;
                                      _pageController.jumpToPage(index);
                                    });
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    alignment: Alignment.center,
                                    width: 70,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: backgroundColor,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: color,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Text(
                                      colorName,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: textColor,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 12),
                      ],

                      // Description
                      const Text(
                        "Description:",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        product['description'] ?? '',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 20),

                      // STORE INFO BUTTON
                      storeLoading
                          ? const Center(child: CircularProgressIndicator())
                          : store != null
                          ? GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StoreProductsScreen(
                                      sellerId: widget.product['sellerId'],
                                      storeName: store?['name'] ?? 'Store',
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 20),
                                decoration: BoxDecoration(
                                  color: AppColors.lavenderLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "Visit Store: ${store!['name']}",
                                      style: const TextStyle(
                                        color: AppColors.lavenderDark,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const Icon(
                                      Icons.arrow_forward,
                                      color: AppColors.lavenderDark,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // STICKY ACTION BUTTONS
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lavenderDark,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final userId = prefs.getString('userId');

                        if (userId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Please log in first"),
                            ),
                          );
                          return;
                        }

                        try {
                          final url = Uri.parse(
                            "http://beadaura-backend.onrender.com/add-to-cart",
                          );
                          final response = await http.post(
                            url,
                            headers: {"Content-Type": "application/json"},
                            body: jsonEncode({
                              "userId": userId,
                              "product": product,
                            }),
                          );

                          if (response.statusCode == 200) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Added to cart")),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text("Failed to add to cart"),
                              ),
                            );
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text("Error: $e")));
                        }
                      },
                      child: const Text(
                        "Add to Cart",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.lavenderMedium,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Order Now tapped")),
                        );
                      },
                      child: const Text(
                        "Order Now",
                        style: TextStyle(color: Colors.white),
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
}
