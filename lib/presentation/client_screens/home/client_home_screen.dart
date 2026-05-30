import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:go_router/go_router.dart';
import 'package:hotel_management_system/core/widgets/icon_shadow_widget.dart';
import 'package:hotel_management_system/data/models/category_model.dart';
import 'package:hotel_management_system/data/repositories/buisness_repository.dart';
import 'package:hotel_management_system/data/repositories/category_repository.dart';
import 'package:hotel_management_system/presentation/client_screens/widgets/category_products_widget.dart';
import 'package:hotel_management_system/presentation/client_screens/widgets/product_search_delegate.dart';
import 'package:hotel_management_system/presentation/client_screens/widgets/product_shimmer_widget.dart';
import 'package:hotel_management_system/routes/client_app_routes.dart';
import 'package:hotel_management_system/state_management/category_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/client_cart_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/product_state_and_notifier.dart';
import 'package:hotel_management_system/state_management/theme_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:shimmer_animation/shimmer_animation.dart';

class ClientHomeScreen extends ConsumerStatefulWidget {
  final ZoomDrawerController drawerController;
  const ClientHomeScreen({super.key, required this.drawerController});

  @override
  ConsumerState<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends ConsumerState<ClientHomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  final CategoryRepository categoryRepository = CategoryRepository(
    businessId: BusinessRepository.temporaryBusinesshId,
    branchId: BusinessRepository.temporaryBranchId,
  );
  List<CategoryModel> categories = [];
  late ScrollController _scrollController;
  late AnimationController _animationController;
  late Animation<double> _animation;
  bool _isVisible = true;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getAllCategories();

    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels > 50 && _isVisible) {
      _isVisible = false;
      _animationController.reverse();
    } else if (_scrollController.position.pixels <= 50 && !_isVisible) {
      _isVisible = true;
      _animationController.forward();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> getAllCategories() async {
    categories = await categoryRepository.getCategories();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final themeController = ref.watch(themeProvider);
    final productRef = ref.watch(productRepositoryProvider);
    final categooryref = ref.read(categoryNotifierprovideer);
    final cartRef = ref.watch(cartProvider);

    return FutureBuilder(
      future: categooryref.getCategories(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Some error occured'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        return DefaultTabController(
          length: categories.length,
          child: Scaffold(
            appBar: AppBar(
              leading: IconButton(
                onPressed: () {
                  ZoomDrawer.of(context)!.toggle();
                },
                icon: IconShadowWidget(icon: Icons.menu_rounded),
              ),
              actions: [
                Badge(
                  alignment: AlignmentDirectional.topEnd,
                  offset: const Offset(-10, 10), // fine-tune X/Y position
                  smallSize: 22,
                  label: Text(cartRef.length.toString()),
                  child: IconButton(
                    onPressed: () {
                      context.goNamed(ClientAppRoutes.cartScreen);
                    },
                    icon: IconShadowWidget(icon: Icons.shopping_cart),
                  ),
                ),
                IconButton(
                  icon: IconShadowWidget(
                    icon: themeController.themeMode == ThemeMode.dark
                        ? Icons.dark_mode
                        : Icons.light_mode,
                  ),
                  onPressed: () {
                    final newMode = themeController.themeMode == ThemeMode.dark
                        ? ThemeMode.light
                        : ThemeMode.dark;
                    ref.read(themeProvider.notifier).updateMode(newMode);
                  },
                ),
                IconButton(
                  onPressed: () {
                    pickColorforTheme();
                  },
                  icon: IconShadowWidget(icon: Icons.color_lens),
                ),
              ],
            ),
            body: NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 30,
                        children: [
                          SizeTransition(
                            sizeFactor: _animation,
                            axisAlignment: -1,
                            child: Text(
                              'Cool Treats\nSweet Moments',
                              style: Theme.of(
                                context,
                              ).textTheme.titleLarge!.copyWith(fontSize: 40),
                            ),
                          ),
                          SizeTransition(
                            sizeFactor: _animation,
                            axisAlignment: -1,
                            child: GestureDetector(
                              onTap: () async {
                                final allProducts = await productRef
                                    .getAllProducts();
                                await showSearch(
                                  context: context,
                                  delegate: ProductSearchDelegate(allProducts),
                                );
                              },
                              child: _buildSearchField(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      TabBar(
                        isScrollable: MediaQuery.of(context).size.width < 600
                            ? true
                            : false,
                        tabs: categories
                            .map((item) => Tab(text: item.name))
                            .toList(),
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: categories.map((category) {
                  return FutureBuilder(
                    future: productRef.getProductsByCategory(
                      category.id,
                    ), // Use category ID
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Shimmer(
                          enabled: true,
                          child: ProductShimmerWidget(),
                        );
                      }
                      if (snapshot.hasError) {
                        return Center(child: Text('Some error occurred'));
                      }
                      if (snapshot.data == null || snapshot.data!.isEmpty) {
                        return Center(
                          child: Text('No products found for this category'),
                        );
                      }
                      return CategoryProducts(
                        productModel: snapshot.data!,
                        categoryName:
                            category.name, // Pass actual category name
                      );
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSearchField() {
    return AbsorbPointer(
      child: TextField(
        controller: searchController,
        decoration: InputDecoration(
          hintText: 'Search',
          filled: true,
          prefixIcon: const Icon(Icons.search_rounded),
        ),
      ),
    );
  }

  void pickColorforTheme() {
    final themeController = ref.watch(themeProvider);
    showDialog(
      context: context,
      builder: (context) {
        Color tempColor = themeController.primaryColor;
        return AlertDialog(
          title: const Text("Pick a color"),
          content: SingleChildScrollView(
            child: BlockPicker(
              pickerColor: themeController.primaryColor,
              onColorChanged: (color) {
                tempColor = color;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                ref.read(themeProvider.notifier).updateColor(tempColor);
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

// class ClientShell extends StatefulWidget {
//   const ClientShell({super.key});

//   @override
//   State<ClientShell> createState() => _ClientShellState();
// }

// class _ClientShellState extends State<ClientShell> {
//   int _selectedIndex = 0;

//   // Define all modules here (single source of truth)
//   final List<_NavItem> _navItems = [
//     _NavItem(
//       "Dashboard",
//       Icons.dashboard,
//       Center(child: Text("Dashboard Page")),
//     ),
//     _NavItem("Staff", Icons.people, Center(child: Text("Staff Management"))),
//     _NavItem(
//       "Products",
//       Icons.shopping_bag,
//       Center(child: Text("Products Management")),
//     ),
//     _NavItem(
//       "Menu",
//       Icons.restaurant_menu,
//       Center(child: Text("Menu Management")),
//     ),
//     _NavItem(
//       "Categories",
//       Icons.category,
//       Center(child: Text("Category Management")),
//     ),
//     _NavItem("Orders", Icons.receipt, Center(child: Text("Orders Management"))),
//     _NavItem("Settings", Icons.settings, Center(child: Text("Settings"))),
//   ];

//   @override
//   Widget build(BuildContext context) {
//     final isDesktop = MediaQuery.of(context).size.width >= 800;

//     return Scaffold(
//       appBar: isDesktop
//           ? null
//           : AppBar(
//               title: Text(_navItems[_selectedIndex].label),
//               leading: Builder(
//                 builder: (context) => IconButton(
//                   icon: Icon(Icons.menu),
//                   onPressed: () => Scaffold.of(context).openDrawer(),
//                 ),
//               ),
//             ),

//       // Drawer for Mobile
//       drawer: isDesktop
//           ? null
//           : Drawer(
//               child: ListView(
//                 children: [
//                   const DrawerHeader(
//                     child: Text("Hotel Admin", style: TextStyle(fontSize: 20)),
//                   ),
//                   ..._navItems.asMap().entries.map(
//                     (entry) => ListTile(
//                       leading: Icon(entry.value.icon),
//                       title: Text(entry.value.label),
//                       selected: _selectedIndex == entry.key,
//                       onTap: () {
//                         setState(() => _selectedIndex = entry.key);
//                         Navigator.pop(context); // close drawer
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//       // Body with sidebar for desktop
//       body: Row(
//         children: [
//           if (isDesktop)
//             NavigationRail(
//               selectedIndex: _selectedIndex,
//               onDestinationSelected: (index) {
//                 setState(() => _selectedIndex = index);
//               },
//               labelType: NavigationRailLabelType.all,
//               destinations: _navItems
//                   .map(
//                     (item) => NavigationRailDestination(
//                       icon: Icon(item.icon),
//                       label: Text(item.label),
//                     ),
//                   )
//                   .toList(),
//             ),

//           // Main content
//           Expanded(
//             child: Container(
//               padding: const EdgeInsets.all(16),
//               child: _navItems[_selectedIndex].page,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// // Helper model for nav items
// class _NavItem {
//   final String label;
//   final IconData icon;
//   final Widget page;
//   const _NavItem(this.label, this.icon, this.page);
// }
