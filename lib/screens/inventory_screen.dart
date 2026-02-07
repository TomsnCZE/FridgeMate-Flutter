import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../models/product.dart';
import '../widgets/product_card.dart';
import '../widgets/product_detail_bottom_sheet.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/add_product_screen.dart';
import '../routes/custom_routes.dart';
import '../services/settings_service.dart';
import '../services/database_service.dart';

class InventoryScreen extends StatefulWidget {
  final VoidCallback? onInventoryChanged;

  const InventoryScreen({super.key, this.onInventoryChanged});

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

    widget.onInventoryChanged?.call();
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
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            ),
          ),
        ),
      ),
    );
  }

    String _trFilterLabel(String raw) {
    // Handle already-localized Czech labels coming from older data/UI
    const csToKey = {
      'Jídlo': 'food',
      'Pití': 'beverage',
      'Nápoj': 'beverage',
      'Ostatní': 'other',
      'Lednice': 'fridge',
      'Mrazák': 'freezer',
      'Spíž': 'pantry',
      'ks': 'pieces',
      'Čerstvé': 'fresh',
      'Brzy expiruje': 'soon',
      'Dnes expiruje': 'today',
      'Prošlé': 'expired',
    };

    final key = csToKey[raw] ?? raw;

    // add_product.* keys
    const addProductKeys = {
      'food',
      'beverage',
      'other',
      'fridge',
      'freezer',
      'pantry',
      'pieces',
    };
    if (addProductKeys.contains(key)) {
      return 'add_product.$key'.tr();
    }

    // inventory.status.* keys
    const statusKeys = {'expired', 'today', 'soon', 'fresh'};
    if (statusKeys.contains(key)) {
      return 'inventory.status.$key'.tr();
    }

    // Fall back (already a readable label)
    return raw;
  }


  String _getActiveFiltersText() {
    final filters = <String>[];
    if (_filterCategory != 'Vše') {
      filters.add(_trFilterLabel(_filterCategory));
    }
    if (_filterType != 'Vše') {
      filters.add(_trFilterLabel(_filterType));
    }
    if (_filterExpiration != 'Vše') {
      filters.add(_trFilterLabel(_filterExpiration));
    }


    return filters.isEmpty
        ? 'inventory.active_filters_none'.tr()
        : 'inventory.active_filters'.tr(
            namedArgs: {'filters': filters.join(', ')},
          );
  }

    String _expirationBannerText({
    required int expired,
    required int today,
    required int soon,
  }) {
    final lang = context.locale.languageCode;

    // Priority: expired > today > soon
    if (expired > 0) {
      if (lang == 'cs') {
        if (expired == 1) return '1 produkt prošel expirací';
        if (expired >= 2 && expired <= 4) {
          return '$expired produkty prošly expirací';
        }
        return '$expired produktů prošlo expirací';
      }
      return 'inventory.expiration.expired'.plural(
        expired,
        namedArgs: {'count': '$expired'},
      );
    }

    if (today > 0) {
      if (lang == 'cs') {
        if (today == 1) return '1 produkt expiruje dnes';
        if (today >= 2 && today <= 4) return '$today produkty expirují dnes';
        return '$today produktů expiruje dnes';
      }
      return 'inventory.expiration.today'.plural(
        today,
        namedArgs: {'count': '$today'},
      );
    }

    // soon > 0
    if (lang == 'cs') {
      if (soon == 1) return '1 produkt brzy expiruje';
      if (soon >= 2 && soon <= 4) return '$soon produkty brzy expirují';
      return '$soon produktů brzy expiruje';
    }

    return 'inventory.expiration.expiring_soon'.plural(
      soon,
      namedArgs: {'count': '$soon'},
    );
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

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final expiredCount = _products.where((p) {
      final d = p.expirationDate;
      if (d == null) return false;
      final exp = DateTime(d.year, d.month, d.day);
      return exp.isBefore(today);
    }).length;

        final todayCount = _products.where((p) {
      final d = p.expirationDate;
      if (d == null) return false;
      final exp = DateTime(d.year, d.month, d.day);
      return exp.isAtSameMomentAs(today);
    }).length;

    final expiringSoonCount = _products.where((p) {
      final d = p.expirationDate;
      if (d == null) return false;
      final exp = DateTime(d.year, d.month, d.day);
      final diff = exp.difference(today).inDays;
      return diff >= 1 && diff <= 3;
    }).length;


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
                  Icon(
                    Icons.filter_alt,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getActiveFiltersText(),
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
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
          if (expiredCount > 0 || todayCount > 0 || expiringSoonCount > 0)
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
                      _expirationBannerText(
                        expired: expiredCount,
                        today: todayCount,
                        soon: expiringSoonCount,
                      ),
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
                    ? ListView.separated(
                        itemCount: filtered.length,
                        itemBuilder: (context, i) => ProductCard(
                          product: filtered[i],
                          onTap: () => _showProductDetail(filtered[i]),
                          onChanged: _loadProducts,
                        ),
                        separatorBuilder: (context, i) => Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Divider(
                            height: 1,
                            thickness: 1,
                            color: theme.colorScheme.outlineVariant.withOpacity(
                              0.25,
                            ),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
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
