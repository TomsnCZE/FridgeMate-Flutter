import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/product_grid_card.dart';
import '../widgets/product_detail_bottom_sheet.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/add_product_screen.dart';
import '../screens/product_edit_screen.dart';
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

  @override
  void initState() {
    super.initState();
    _loadViewMode();
    _loadProducts();
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
            '${result.name} byl přidán do skladu',
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
            '${result.name} byl přidán do skladu',
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

  Future<void> _showEditScreen(int index) async {
    final result = await Navigator.push(
      context,
      SlideRightRoute(
        page: EditProductScreen(product: _products[index]),
      ),
    );

    if (result != null) {
      if (result == 'delete') {
        await _loadProducts();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_products[index].name} byl smazán',
              style: const TextStyle(color: Colors.white),
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (result is Product) {
        await _loadProducts();
        if (!mounted) return;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${(result).name} byl upraven',
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
            ),
            backgroundColor: isDark ? Colors.grey[800] : Colors.white,
            behavior: SnackBarBehavior.floating,
            elevation: 6,
          ),
        );
      }
    }
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
      final matchesSearch = p.name.toLowerCase().contains(_search.toLowerCase());
      final matchesCategory = _filterCategory == 'Vše' || p.category == _filterCategory;
      final matchesType = _filterType == 'Vše' || (p.extra?['type'] ?? 'Jídlo') == _filterType;
      final matchesExpiration = _checkExpirationFilter(p);

      return matchesSearch && matchesCategory && matchesType && matchesExpiration;
    }).toList();
  }

  bool _checkExpirationFilter(Product p) {
    if (_filterExpiration == 'Vše') return true;
    if (p.expirationDate == null) {
      return _filterExpiration == 'Čerstvé';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiration = DateTime(p.expirationDate!.year, p.expirationDate!.month, p.expirationDate!.day);

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

  String _getActiveFiltersText() {
    final filters = [];
    if (_filterCategory != 'Vše') filters.add(_filterCategory);
    if (_filterType != 'Vše') filters.add(_filterType);
    if (_filterExpiration != 'Vše') filters.add(_filterExpiration);

    return filters.isEmpty ? 'Žádné aktivní filtry' : 'Filtry: ${filters.join(', ')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    final filtered = filteredProducts;
    final hasActiveFilters = _filterCategory != 'Vše' || _filterType != 'Vše' || _filterExpiration != 'Vše';

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
          // HLEDÁNÍ
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: theme.hintColor),
                hintText: 'Hledat produkt...',
                hintStyle: TextStyle(color: theme.hintColor),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
              ),
              onChanged: (val) => setState(() => _search = val),
            ),
          ),

          // FILTRY A ZOBRAZENÍ
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filtrovat produkty'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: _showFilterSheet,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _viewMode == 'list' ? Icons.grid_view : Icons.view_list,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  onPressed: _toggleViewMode,
                  tooltip: _viewMode == 'list' ? 'Zobrazit jako mřížku' : 'Zobrazit jako seznam',
                ),
              ],
            ),
          ),

          // INDIKÁTOR AKTIVNÍCH FILTRŮ
          if (hasActiveFilters)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_alt, size: 16, color: theme.hintColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getActiveFiltersText(),
                      style: TextStyle(
                        color: theme.hintColor,
                        fontSize: 14,
                      ),
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
                    child: Icon(Icons.close, size: 16, color: theme.hintColor),
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
                    : Theme.of( context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Theme.of(context).colorScheme.primary),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      expiredCount > 0
                          ? '$expiredCount produktů prošlo expirací'
                          : '$expiringSoonCount produktů brzy expiruje',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // SEZNAM PRODUKTŮ
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
                          'Žádné produkty',
                          style: TextStyle(
                            color: theme.hintColor,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          hasActiveFilters
                              ? 'Zkus změnit filtry'
                              : 'Přidej první produkt pomocí tlačítka +',
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
                          index: _products.indexOf(filtered[i]),
                          onEdit: () => _showEditScreen(_products.indexOf(filtered[i])),
                          onDelete: () => _showEditScreen(_products.indexOf(filtered[i])), // open edit to delete
                          onTap: () => _showProductDetail(filtered[i]),
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => ProductGridCard(
                          product: filtered[i],
                          index: _products.indexOf(filtered[i]),
                          onEdit: () => _showEditScreen(_products.indexOf(filtered[i])),
                          onDelete: () => _showEditScreen(_products.indexOf(filtered[i])),
                          onTap: () => _showProductDetail(filtered[i]),
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
            label: 'Přidat ručně',
            onTap: _handleAddPressed,
          ),
          SpeedDialChild(
            child: const Icon(Icons.qr_code_scanner),
            label: 'Skenovat',
            onTap: _handleScanPressed,
          ),
        ],
      ),
    );
  }
}