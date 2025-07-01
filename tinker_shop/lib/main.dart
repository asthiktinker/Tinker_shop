import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart' as cs;
import 'package:url_launcher/url_launcher.dart';

void main() => runApp(const TinkerSpaceApp());

class TinkerSpaceApp extends StatelessWidget {
  const TinkerSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TinkerSpace.in',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF0D47A1),
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        textTheme: const TextTheme(
          titleMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          bodyMedium: TextStyle(fontSize: 14),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

class AppColors {
  static const Color headerFooter = Color(0xFF0D47A1);
  static const Color primaryButton = Color(0xFF2196F3);
  static const Color highlight = Color(0xFFFFEB3B);
  static const Color success = Color(0xFF4CAF50);
  static const Color background = Color(0xFFFFFFFF);
  static const Color sectionBg = Color(0xFFF5F5F5);
  static const Color textDark = Color(0xFF2D3748);
  static const Color textLight = Color(0xFFFFFFFF);
}

// API Service Class
class ApiService {
  static const String baseUrl = "https://tinkerspace.in/tinker_product/get_poduct.php";
  
  Future<List<Map<String, dynamic>>> fetchProducts() async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Handle different API response structures
        if (data is Map && data.containsKey('products')) {
          return List<Map<String, dynamic>>.from(data['products']);
        } else if (data is List) {
          return List<Map<String, dynamic>>.from(data);
        } else {
          throw Exception('Invalid API response format');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Request timed out');
    } on FormatException {
      throw Exception('Invalid response format');
    } catch (e) {
      throw Exception('Failed to load products: $e');
    }
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentCarouselIndex = 0;
  String selectedKit = 'All';
  String selectedProject = 'All';
  int crossAxisCount = 4;

  // API related variables
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> filteredProducts = [];
  bool isLoading = true;
  String errorMessage = '';
  final ApiService _apiService = ApiService();

  final List<String> carouselImages = [
    'assets/images/carousel1.jpg',
    'assets/images/carousel2.jpg',
    'assets/images/carousel3.jpg',
    'assets/images/carousel4.jpg',
    'assets/images/carousel5.jpg',
  ];

  final List<Map<String, dynamic>> kits = [
    {'title': 'Robotics', 'sub': ['Starter Kits', 'Advanced', 'Components']},
    {'title': 'Electronics', 'sub': ['Basic Circuits', 'Microcontrollers', 'Sensors']},
    {'title': 'Science', 'sub': ['Chemistry', 'Physics', 'Biology']},
    {'title': 'Coding', 'sub': ['Python', 'Scratch', 'Arduino']},
  ];

  final List<Map<String, dynamic>> projects = [
    {'title': 'Beginner', 'sub': ['Simple Robots', 'Basic Circuits', 'Weather Station']},
    {'title': 'Intermediate', 'sub': ['Home Automation', 'Drone Build', 'Smart Garden']},
    {'title': 'Advanced', 'sub': ['AI Projects', 'IoT Systems', 'Robotic Arm']},
    {'title': 'Competitions', 'sub': ['Science Fair', 'Robo Wars', 'Innovation Challenge']},
  ];

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final data = await _apiService.fetchProducts();
      setState(() {
        products = data;
        filteredProducts = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
        // Fallback to static data if API fails
        products = _getFallbackProducts();
        filteredProducts = products;
      });
    }
  }

  List<Map<String, dynamic>> _getFallbackProducts() {
    return [
      {
        'title': 'ABC Kit',
        'description': 'Beginner robotics kit with 3 projects',
        'price': '₹1500',
        'tag': 'mppA000',
        'in_stock': true,
        'image_url': null,
      },
      {
        'title': 'Smart Home Kit',
        'description': 'IoT automation starter pack',
        'price': '₹2500',
        'tag': 'smt001',
        'in_stock': true,
        'image_url': null,
      },
      {
        'title': 'Arduino Mega Kit',
        'description': 'Complete electronics learning kit',
        'price': '₹3200',
        'tag': 'ard002',
        'in_stock': true,
        'image_url': null,
      },
      {
        'title': 'Drone Builder',
        'description': 'Build your own quadcopter',
        'price': '₹4500',
        'tag': 'drn003',
        'in_stock': false,
        'image_url': null,
      },
    ];
  }

  void _filterProducts() {
    setState(() {
      filteredProducts = products.where((product) {
        bool matchesKit = selectedKit == 'All' || 
            (product['category']?.toString().toLowerCase().contains(selectedKit.toLowerCase()) ?? false);
        bool matchesProject = selectedProject == 'All' || 
            (product['type']?.toString().toLowerCase().contains(selectedProject.toLowerCase()) ?? false);
        
        return matchesKit && matchesProject;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    crossAxisCount = screenWidth > 1200 ? 4 : screenWidth > 800 ? 3 : 2;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.headerFooter,
        title: const Text(
          'TinkerSpace.in',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            letterSpacing: 1.2,
            color: Colors.white,
          ),
        ),
        actions: [
          _buildSearchWidget(context, screenWidth),
          const SizedBox(width: 20),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchProducts,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // Dropdown Navigation
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: Colors.grey[100],
                child: Row(
                  children: [
                    _buildDropdown(
                      label: 'Kits',
                      items: kits,
                      selectedValue: selectedKit,
                      onChanged: (value) {
                        setState(() => selectedKit = value!);
                        _filterProducts();
                      },
                    ),
                    const SizedBox(width: 20),
                    _buildDropdown(
                      label: 'Projects',
                      items: projects,
                      selectedValue: selectedProject,
                      onChanged: (value) {
                        setState(() => selectedProject = value!);
                        _filterProducts();
                      },
                    ),
                    const Spacer(),
                    if (isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ),

              // Image Carousel
              Container(
                height: 300,
                child: Stack(
                  children: [
                    PageView.builder(
                      itemCount: carouselImages.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentCarouselIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primaryButton.withOpacity(0.8),
                                AppColors.headerFooter.withOpacity(0.8),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.science,
                                  size: 80,
                                  color: Colors.white,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'STEM Learning Kit ${index + 1}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Explore, Build, Learn with TinkerSpace',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          carouselImages.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentCarouselIndex == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Product Grid
              Container(
                padding: EdgeInsets.all(screenWidth > 600 ? 20 : 12),
                decoration: BoxDecoration(
                  color: AppColors.sectionBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Top Products & Our Shop',
                          style: TextStyle(
                            fontSize: screenWidth > 600 ? 24 : 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        Text(
                          '${filteredProducts.length} products',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Loading State
                    if (isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Loading products...'),
                            ],
                          ),
                        ),
                      ),

                    // Error State
                    if (errorMessage.isNotEmpty && !isLoading)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(40),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                size: 48,
                                color: Colors.red,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Error: $errorMessage',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.red),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _fetchProducts,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Empty State
                    if (!isLoading && errorMessage.isEmpty && filteredProducts.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.inventory_2_outlined,
                                size: 48,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No products found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Products Grid
                    if (!isLoading && errorMessage.isEmpty && filteredProducts.isNotEmpty)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: 0.75,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filteredProducts.length,
                        itemBuilder: (context, index) {
                          return _buildProductCard(filteredProducts[index]);
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 20),
              const Footer(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primaryButton,
        onPressed: () {},
        child: const Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildSearchWidget(BuildContext context, double screenWidth) {
    final searchButton = TextButton.icon(
      icon: const Icon(Icons.search, color: Colors.white),
      label: const Text('Search Products',
          style: TextStyle(color: Colors.white)),
      onPressed: () => _openSearch(context),
    );

    final searchIcon = IconButton(
      icon: const Icon(Icons.search, color: Colors.white),
      tooltip: 'Search Products',
      onPressed: () => _openSearch(context),
    );

    return screenWidth > 700 ? searchButton : searchIcon;
  }

  void _openSearch(BuildContext context) async {
    final selectedProduct = await showSearch<Map<String, dynamic>?>(
      context: context,
      delegate: ProductSearchDelegate(products),
    );

    if (selectedProduct != null && selectedProduct.isNotEmpty) {
      _showProductDetails(selectedProduct);
    }
  }

  Widget _buildDropdown({
    required String label,
    required List<Map<String, dynamic>> items,
    required String selectedValue,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue == 'All' ? null : selectedValue,
          hint: Text('$label ▼'),
          icon: const Icon(Icons.arrow_drop_down),
          items: [
            const DropdownMenuItem(value: 'All', child: Text('All')),
            ...items.map((item) => DropdownMenuItem(
              value: item['title'],
              child: Text(item['title']),
            )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final bool inStock = product['in_stock'] ?? true;
    final String imageUrl = product['image_url'] ?? '';
    
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.sectionBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.science,
                            size: 40,
                            color: AppColors.textDark,
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          );
                        },
                      ),
                    )
                  : const Icon(
                      Icons.science,
                      size: 40,
                      color: AppColors.textDark,
                    ),
            ),
            const SizedBox(height: 12),
            
            // Product Title
            Text(
              product['title'] ?? product['name'] ?? 'No Title',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            
            // Product Description
            Text(
              product['description'] ?? 'No description available',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            
            // Product Price
            Text(
              product['price'] ?? product['formatted_price'] ?? '₹0',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.headerFooter,
              ),
            ),
            const SizedBox(height: 8),
            
            // Stock Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: inStock ? AppColors.success : Colors.red,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                inStock ? 'IN STOCK' : 'OUT OF STOCK',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            
            // Buy Button
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: inStock ? () {
                      // Handle buy now action
                      _showProductDetails(product);
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryButton,
                      disabledBackgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: Text(
                      inStock ? 'Buy Now' : 'Unavailable',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
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

  void _showProductDetails(Map<String, dynamic> product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }
}

class ProductSearchDelegate extends SearchDelegate<Map<String, dynamic>?> {
  final List<Map<String, dynamic>> allProducts;

  ProductSearchDelegate(this.allProducts);

  @override
  ThemeData appBarTheme(BuildContext context) {
    final theme = Theme.of(context);
    return theme.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.headerFooter,
        iconTheme: theme.primaryIconTheme.copyWith(color: Colors.white),
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white70),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          tooltip: 'Clear',
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      tooltip: 'Back',
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final filtered = allProducts.where((product) {
      final title = product['title']?.toString().toLowerCase() ?? '';
      final description = product['description']?.toString().toLowerCase() ?? '';
      final searchQuery = query.toLowerCase();

      return title.contains(searchQuery) || description.contains(searchQuery);
    }).toList();

    return Container(
      color: AppColors.background,
      child: ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final product = filtered[index];
          return ListTile(
            title: Text(product['title'] ?? 'Product'),
            subtitle: Text(
              product['description'] ?? 'No description',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              close(context, product);
            },
          );
        },
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    final List<String> images = [
      'assets/images/product1.jpg',
      'assets/images/product2.jpg',
      'assets/images/product3.jpg',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(product['title'] ?? 'Product Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Carousel
            cs.CarouselSlider(
              options: cs.CarouselOptions(
                height: 300,
                autoPlay: true,
                aspectRatio: 16 / 9,
                viewportFraction: 1.0,
              ),
              items: images.map((image) {
                return Builder(
                  builder: (BuildContext context) {
                    return Container(
                      width: MediaQuery.of(context).size.width,
                      margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        color: AppColors.sectionBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Image.asset(
                        image,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.science,
                            size: 80,
                            color: AppColors.textDark,
                          );
                        },
                      ),
                    );
                  },
                );
              }).toList(),
            ),

            // Product Info
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product['title'] ?? 'No Title',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Price: ${product['price'] ?? '₹0'}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.headerFooter,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    product['description'] ?? 'No description available',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _showEnquiryForm(context, product, 'Get Product'),
                          icon: const Icon(Icons.shopping_cart),
                          label: const Text('Get Product'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryButton,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showEnquiryForm(
                              context, product, 'Customize Product'),
                          icon: const Icon(Icons.build),
                          label: const Text('Customize'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.highlight,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Footer(),
          ],
        ),
      ),
    );
  }
}

class Footer extends StatelessWidget {
  const Footer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.headerFooter,
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'TinkerSpace.in',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 768) {
                return const FooterRowDesktop();
              } else {
                return const FooterColumnMobile();
              }
            },
          ),
          const SizedBox(height: 20),
          const Divider(color: Colors.white24),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '© 2024 TinkerSpace.in - Help Center',
                style: TextStyle(color: Colors.white70),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Terms & Service',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text(
                      'Privacy & Policy',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _showEnquiryForm(
    BuildContext context, Map<String, dynamic> product, String enquiryType) {
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final detailsController = TextEditingController();

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('$enquiryType Enquiry'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: detailsController,
              decoration: const InputDecoration(
                labelText: 'Additional Details',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            _submitEnquiry(
              nameController.text,
              phoneController.text,
              detailsController.text,
              product,
              enquiryType,
              context,
            );
            Navigator.pop(context);
          },
          child: const Text('Submit Enquiry'),
        ),
      ],
    ),
  );
}

void _submitEnquiry(
  String name,
  String phone,
  String details,
  Map<String, dynamic> product,
  String enquiryType,
  BuildContext context,
) async {
  if (name.isEmpty || phone.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please fill all required fields'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }

  const String shopOwnerWhatsAppNumber = "6364063644";
  const String countryCode = "91";

  final productTitle = product['title'] ?? 'Product';
  final productPrice = product['price'] ?? '₹0';

  final message = '''
*New Product Enquiry*

Name: $name
Phone: $phone
Product: $productTitle
Price: $productPrice
Enquiry Type: $enquiryType

Additional Details:
$details
''';

  final encodedMessage = Uri.encodeComponent(message);
  final whatsappUrl =
      "https://wa.me/$countryCode$shopOwnerWhatsAppNumber?text=$encodedMessage";

  if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
    await launchUrl(Uri.parse(whatsappUrl));
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not launch WhatsApp'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// Footer Components
class FooterRowDesktop extends StatelessWidget {
  const FooterRowDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'TinkerSpace\nLogo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 40),
        const Expanded(
          child: FooterColumn(
            title: 'About Us',
            items: ['Robotics', 'AgriTech', 'Sensors', 'IoT'],
          ),
        ),
        const Expanded(
          child: FooterColumn(
            title: 'Services',
            items: ['IoT', 'Apps', 'Customize'],
          ),
        ),
        const Expanded(
          child: FooterColumn(
            title: 'Help',
            items: ['Support', 'Return', 'Feedback', 'Contact Us'],
          ),
        ),
      ],
    );
  }
}

class FooterColumnMobile extends StatelessWidget {
  const FooterColumnMobile({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'TinkerSpace\nLogo',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 20),
        const FooterColumn(
          title: 'About Us',
          items: ['Robotics', 'AgriTech', 'Sensors', 'IoT'],
        ),
        const SizedBox(height: 16),
        const FooterColumn(
          title: 'Services',
          items: ['IoT', 'Apps', 'Customize'],
        ),
        const SizedBox(height: 16),
        const FooterColumn(
          title: 'Help',
          items: ['Support', 'Return', 'Feedback', 'Contact Us'],
        ),
      ],
    );
  }
}

class FooterColumn extends StatelessWidget {
  final String title;
  final List<String> items;

  const FooterColumn({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '• $item',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        )),
      ],
    );
  }
}