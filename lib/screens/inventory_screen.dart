import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/product_grid_card.dart';
import '../widgets/product_detail_bottom_sheet.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/add_product_screen.dart';
import '../routes/custom_routes.dart';
import '../services/settings_service.dart';
import '../services/database_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<Product> _products = [];
  String _search = '';
  String _filterCategory = 'Vše';
  String _filterType = 'Vše';
  String _filterExpiration = 'Vše';
  String _viewMode = 'list';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = _search;
    _loadViewMode();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadViewMode() async {
    final mode = await SettingsService.getViewMode();
    setState(() {
      _viewMode = mode;
    });
  }

  Future<void> _loadProducts() async {
    final data = await DatabaseService.instance.getAllProducts();
    setState(() {
      _products = data.map((e) => Product.fromMap(e)).toList();
    });
  }

  // přidání: očekává Product jako návrat z AddProductScreen
  Future<void> _handleAddPressed() async {
    final result = await Navigator.push<Product?>(
      context,
      SlideLeftRoute(page: const AddProductScreen()),
    );

    if (result != null) {
      await _loadProducts();
      if (!mounted) return;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'inventory.snackbar_added'.tr(namedArgs: {'name': result.name}),
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          backgroundColor: isDark ? Colors.grey[800] : Colors.white,
          behavior: SnackBarBehavior.floating,
          elevation: 6,
        ),
      );
    }
  }

  Future<void> _handleScanPressed() async {
    final result = await Navigator.push<Product?>(
      context,
      MaterialPageRoute(builder: (_) => const QRScannerScreen()),
    );

    if (result != null) {
      await _loadProducts();
      if (!mounted) return;
      final isDark = Theme.of(context).brightness == Brightness.dark;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'inventory.snackbar_added'.tr(namedArgs: {'name': result.name}),
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
          ),
          backgroundColor: isDark ? Colors.grey[800] : Colors.white,
          behavior: SnackBarBehavior.floating,
          elevation: 6,
        ),
      );
    }
  }

  void _showProductDetail(Product product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => ProductDetailBottomSheet(product: product),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => FilterBottomSheet(
        currentCategory: _filterCategory,
        currentType: _filterType,
        currentExpiration: _filterExpiration,
        onFiltersChanged: (category, type, expiration) {
          setState(() {
            _filterCategory = category;
            _filterType = type;
            _filterExpiration = expiration;
          });
        },
      ),
    );
  }

  void _toggleViewMode() async {
    final newMode = _viewMode == 'list' ? 'grid' : 'list';
    setState(() {
      _viewMode = newMode;
    });
    await SettingsService.setViewMode(newMode);
  }

  List<Product> get filteredProducts {
    return _products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(
        _search.toLowerCase(),
      );
      final matchesCategory =
          _filterCategory == 'Vše' || p.category == _filterCategory;
      final matchesType =
          _filterType == 'Vše' || (p.extra?['type'] ?? 'Jídlo') == _filterType;
      final matchesExpiration = _checkExpirationFilter(p);

      return matchesSearch &&
          matchesCategory &&
          matchesType &&
          matchesExpiration;
    }).toList();
  }

  bool _checkExpirationFilter(Product p) {
    if (_filterExpiration == 'Vše') return true;
    if (p.expirationDate == null) {
      return _filterExpiration == 'Čerstvé';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiration = DateTime(
      p.expirationDate!.year,
      p.expirationDate!.month,
      p.expirationDate!.day,
    );

    final difference = expiration.difference(today).inDays;

    switch (_filterExpiration) {
      case 'Čerstvé':
        return difference > 3;
      case 'Brzy expiruje':
        return difference >= 1 && difference <= 3;
      case 'Dnes expiruje':
        return difference == 0;
      case 'Prošlé':
        return difference < 0;
      default:
        return true;
    }
  }

  Widget _buildTopBar(ThemeData theme) {
    final cs = theme.colorScheme;

    return Material(
      color: cs.surface,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: SearchBar(
            controller: _searchController,
            hintText: 'inventory.search_hint'.tr(),
            leading: Icon(Icons.search, color: cs.onSurfaceVariant),
            trailing: [
              IconButton(
                tooltip: 'inventory.tooltip_filter'.tr(),
                onPressed: _showFilterSheet,
                icon: Icon(Icons.tune, color: cs.onSurfaceVariant),
              ),
              IconButton(
                tooltip: _viewMode == 'list'
                    ? 'inventory.tooltip_grid'.tr()
                    : 'inventory.tooltip_list'.tr(),
                onPressed: _toggleViewMode,
                icon: Icon(
                  _viewMode == 'list' ? Icons.grid_view : Icons.view_list,
                  color: cs.primary,
                ),
              ),
            ],
            onChanged: (val) {
              setState(() => _search = val);
            },
            padding: const MaterialStatePropertyAll(
              EdgeInsets.symmetric(horizontal: 14),
            ),
            backgroundColor: MaterialStatePropertyAll(
              cs.surfaceContainerHighest,
            ),
            elevation: const MaterialStatePropertyAll(0),
            shape: MaterialStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getActiveFiltersText() {
    final filters = [];
    if (_filterCategory != 'Vše') filters.add(_filterCategory);
    if (_filterType != 'Vše') filters.add(_filterType);
    if (_filterExpiration != 'Vše') filters.add(_filterExpiration);

    return filters.isEmpty
        ? 'inventory.active_filters_none'.tr()
        : 'inventory.active_filters'.tr(namedArgs: {
            'filters': filters.join(', '),
          });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final filtered = filteredProducts;
    final hasActiveFilters =
        _filterCategory != 'Vše' ||
        _filterType != 'Vše' ||
        _filterExpiration != 'Vše';

    final expiredCount = _products
        .where(
          (p) =>
              p.expirationDate != null &&
              p.expirationDate!.isBefore(DateTime.now()),
        )
        .length;

    final expiringSoonCount = _products
        .where(
          (p) =>
              p.expirationDate != null &&
              p.expirationDate!.isAfter(DateTime.now()) &&
              p.expirationDate!.difference(DateTime.now()).inDays <= 3,
        )
        .length;

    return Scaffold(
      body: Column(
        children: [
          _buildTopBar(theme),

          // INDIKÁTOR AKTIVNÍCH FILTRŮ
          if (hasActiveFilters)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.6),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_alt, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getActiveFiltersText(),
                      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 14),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _filterCategory = 'Vše';
                        _filterType = 'Vše';
                        _filterExpiration = 'Vše';
                      });
                    },
                    child: Tooltip(
                      message: 'inventory.clear_filters'.tr(),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // UPOZORNĚNÍ NA EXPIRACI
          if (expiredCount > 0 || expiringSoonCount > 0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? const Color.fromARGB(255, 91, 91, 91).withOpacity(0.3)
                    : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      expiredCount > 0
                          ? 'inventory.expiration.expired'.tr(namedArgs: {
                              'count': expiredCount.toString(),
                            })
                          : 'inventory.expiration.expiring_soon'.tr(namedArgs: {
                              'count': expiringSoonCount.toString(),
                            }),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: theme.hintColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'inventory.empty.title'.tr(),
                          style: TextStyle(
                            color: theme.hintColor,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          hasActiveFilters
                              ? 'inventory.empty.subtitle_filters'.tr()
                              : 'inventory.empty.subtitle_no_products'.tr(),
                          style: TextStyle(
                            color: theme.hintColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  )
                : _viewMode == 'list'
                ? ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => ProductCard(
                      product: filtered[i],
                      onTap: () => _showProductDetail(filtered[i]),
                      onChanged: _loadProducts,
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.75,
                        ),
                    itemCount: filtered.length,
                    itemBuilder: (context, i) => ProductGridCard(
                      product: filtered[i],
                      index: _products.indexOf(filtered[i]),
                      onTap: () => _showProductDetail(filtered[i]),
                      onChanged: _loadProducts,
                    ),
                  ),
          ),
        ],
      ),

      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        overlayColor: Colors.black,
        overlayOpacity: 0.4,
        spacing: 12,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add),
            label: 'inventory.actions.add_manual'.tr(),
            onTap: _handleAddPressed,
          ),
          SpeedDialChild(
            child: const Icon(Icons.qr_code_scanner),
            label: 'inventory.actions.scan_qr'.tr(),
            onTap: _handleScanPressed,
          ),
        ],
      ),
    );
  }
}
