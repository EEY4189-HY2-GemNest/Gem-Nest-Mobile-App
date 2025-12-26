import 'package:animated_bottom_navigation_bar/animated_bottom_navigation_bar.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gemnest_mobile_app/providers/banner_provider.dart';
import 'package:gemnest_mobile_app/screen/auction_screen/auction_screen.dart';
import 'package:gemnest_mobile_app/screen/auth_screens/login_screen.dart';
import 'package:gemnest_mobile_app/screen/cart_screen/cart_screen.dart';
import 'package:gemnest_mobile_app/screen/category_screen/category_card.dart';
import 'package:gemnest_mobile_app/screen/order_history_screen/oreder_history_screen.dart';
import 'package:gemnest_mobile_app/screen/product_screen/product_card.dart';
import 'package:gemnest_mobile_app/screen/profile_screen/profile_screen.dart';
import 'package:gemnest_mobile_app/theme/app_theme.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final iconList = const [
    Icons.home,
    Icons.shopping_cart,
    Icons.receipt,
    Icons.person,
  ];
  String userName = 'Guest';
  List<Map<String, dynamic>> popularProducts = [];

  @override
  void initState() {
    super.initState();
    _fetchUserName();
    _fetchRandomGems();
  }

  Future<void> _fetchUserName() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          setState(() {
            userName = userDoc['name'] as String? ?? 'Guest';
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching user data: $e');
    }
  }

  Future<void> _fetchRandomGems() async {
    try {
      final productsSnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('approvalStatus', isEqualTo: 'approved')
          .get();

      final List<Map<String, dynamic>> products = [];
      for (var doc in productsSnapshot.docs) {
        products.add({
          'id': doc.id,
          'imageUrl': doc['imageUrl'],
          'title': doc['title'],
          'pricing': doc['pricing'],
        });
      }

      products.shuffle();
      final randomProducts = products.take(2).toList();

      setState(() {
        popularProducts = randomProducts;
      });
    } catch (e) {
      debugPrint('Error fetching products: $e');
    }
  }

  void _onItemTapped(int index) {
    // Only update selected index for home (index 0)
    if (index == 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return;
    }

    // For other screens, navigate but reset index when returning
    switch (index) {
      case 1:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const CartScreen()),
        ).then((_) {
          // Reset to home index when returning
          setState(() {
            _selectedIndex = 0;
          });
        });
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const OrderHistoryScreen()),
        ).then((_) {
          // Reset to home index when returning
          setState(() {
            _selectedIndex = 0;
          });
        });
        break;
      case 3:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfileScreen()),
        ).then((_) {
          // Reset to home index when returning
          setState(() {
            _selectedIndex = 0;
          });
        });
        break;
    }
  }

  Future<bool> _onWillPop() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            title: const Text('Logout',
                style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child:
                    const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    await FirebaseAuth.instance.signOut();
                    if (mounted) {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  } catch (e) {
                    debugPrint('Error during logout: $e');
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.errorRed,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child:
                    const Text('Logout', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => BannerProvider()..fetchBannerImages(),
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
              ),
            ),
            elevation: 4,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/logo_new.png', height: 35),
                const SizedBox(width: 8),
                Text(
                  'GemNest Mobile App',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white, size: 24),
                onPressed: _onWillPop,
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _fetchRandomGems,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Welcome $userName,',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Consumer<BannerProvider>(
                    builder: (context, bannerProvider, child) {
                      if (bannerProvider.isLoading) {
                        return const SizedBox(
                          height: 150,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      if (bannerProvider.error != null) {
                        return SizedBox(
                          height: 150,
                          child: Center(
                            child: Text(
                              bannerProvider.error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        );
                      }
                      if (bannerProvider.bannerList.isEmpty) {
                        return const SizedBox(
                          height: 150,
                          child: Center(
                            child: Text(
                              'No banners available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: CarouselSlider(
                          options: CarouselOptions(
                            height: 150,
                            autoPlay: true,
                            enlargeCenterPage: false,
                            viewportFraction: 1.0,
                            aspectRatio: 16 / 9,
                          ),
                          items: bannerProvider.bannerList.map((imageUrl) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Center(
                                    child: Text(
                                      'Failed to load image',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Categories',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => Scaffold(
                                  appBar: AppBar(
                                      title: const Text('All Categories')),
                                  body: const Center(
                                      child: Text(
                                          'All categories will be displayed here.')),
                                ),
                              ),
                            );
                          },
                          child: const Text(
                            'See All',
                            style: TextStyle(fontSize: 14, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.0,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    delegate: SliverChildListDelegate(
                      const [
                        CategoryCard(
                            imagePath: 'assets/images/category1.jpg',
                            title: 'Blue Sapphires'),
                        CategoryCard(
                            imagePath: 'assets/images/category2.jpg',
                            title: 'White Sapphires'),
                        CategoryCard(
                            imagePath: 'assets/images/category3.jpg',
                            title: 'Yellow Sapphires'),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: const Text(
                      'Popular Gems',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (popularProducts.isNotEmpty) {
                          final product = popularProducts[index];
                          return ProductCard(
                            id: product['id'] as String,
                            imagePath: product['imageUrl'] as String,
                            title: product['title'] as String,
                            price:
                                'Rs. ${(product['pricing'] as num).toStringAsFixed(2)}',
                            product: product,
                          );
                        }
                        return const SizedBox.shrink();
                      },
                      childCount: popularProducts.length,
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AuctionScreen()),
              ).then((_) {
                // Reset to home index when returning from auction
                setState(() {
                  _selectedIndex = 0;
                });
              });
            },
            backgroundColor: AppTheme.mediumBlue,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            elevation: 8,
            child: const Icon(Icons.gavel),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          bottomNavigationBar: AnimatedBottomNavigationBar(
            icons: iconList,
            activeIndex: _selectedIndex,
            gapLocation: GapLocation.center,
            notchSmoothness: NotchSmoothness.smoothEdge,
            onTap: _onItemTapped,
            backgroundColor: AppTheme.lightBlue,
            activeColor: AppTheme.primaryBlue,
            leftCornerRadius: 32,
            rightCornerRadius: 32,
          ),
        ),
      ),
    );
  }
}
