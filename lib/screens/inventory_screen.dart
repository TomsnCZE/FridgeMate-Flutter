import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import '../models/product.dart';
import '../widgets/product_list.dart';
import '../widgets/product_detail_bottom_sheet.dart';
import '../widgets/filter_bottom_sheet.dart';
import '../widgets/action_sheet.dart';
import '../screens/qr_scanner_screen.dart';
import '../screens/add_product_screen.dart';
import '../screens/product_edit_screen.dart';

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
  bool _isSelectionMode = false;
  final Set<Product> _selectedProducts = <Product>{};
  String _filterCategory = 'all';
  String _filterType = 'all';
  String _filterExpiration = 'all';
  String _viewMode = 'list';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = _search;
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final data = await DatabaseService.instance.getAllProducts();
    setState(() {
      _products = data.map((e) => Product.fromMap(e)).toList();
    });

    widget.onInventoryChanged?.call();
  }

  Future<void> _handleAddPressed() async {
    final result = await Navigator.push<Product?>(
      context,
      MaterialPageRoute(builder: (_) => const AddProductScreen()),
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

  int get _selectedCount => _selectedProducts.length;

  String _selectedCountText(int count) {
    final lang = context.locale.languageCode;
    if (lang == 'cs') {
      if (count == 1) return '1 vybraný';
      if (count >= 2 && count <= 4) return '$count vybrané';
      return '$count vybraných';
    }

    return 'inventory.selection.selected'.plural(
      count,
      namedArgs: {'count': '$count'},
    );
  }

  String _deleteDialogMessageText(int count) {
    final lang = context.locale.languageCode;

    if (lang == 'cs') {
      if (count == 1) return 'Opravdu chcete smazat tento produkt?';
      if (count >= 2 && count <= 4)
        return 'Opravdu chcete smazat $count produkty?';
      return 'Opravdu chcete smazat $count produktů?';
    }

    return 'inventory.delete_dialog.message'.plural(
      count,
      namedArgs: {'count': '$count'},
    );
  }

  void _enterSelectionMode(Product initial) {
    setState(() {
      _isSelectionMode = true;
      _selectedProducts
        ..clear()
        ..add(initial);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedProducts.clear();
    });
  }

  void _toggleSelection(Product p, bool selected) {
    setState(() {
      if (selected) {
        _selectedProducts.add(p);
      } else {
        _selectedProducts.remove(p);
        if (_selectedProducts.isEmpty) {
          _isSelectionMode = false;
        }
      }
    });
  }

  Future<void> _confirmAndDeleteSelected() async {
    if (_selectedProducts.isEmpty) return;

    final count = _selectedProducts.length;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('inventory.delete_dialog.title'.tr()),
          content: Text(_deleteDialogMessageText(count)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('inventory.delete_dialog.message.cancel').tr(),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('inventory.delete_dialog.message.confirm').tr(),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;
    for (final p in _selectedProducts.toList()) {
      await DatabaseService.instance.deleteProduct(p.id!);
    }

    await _loadProducts();
    if (!mounted) return;

    _exitSelectionMode();
  }

  Product? get _singleSelected =>
      _selectedProducts.length == 1 ? _selectedProducts.first : null;

  void _editSingleSelected() {
    final p = _singleSelected;
    if (p == null) return;
    Navigator.push<Product?>(
      context,
      MaterialPageRoute(builder: (_) => EditProductScreen(product: p)),
    ).then((result) async {
      if (result == null) return;
      await _loadProducts();
      if (!mounted) return;
      _exitSelectionMode();
    });
  }

  void _adjustQuantitySingleSelected() {
    final p = _singleSelected;
    if (p == null) return;
    showDialog(
      context: context,
      builder: (_) => QuantityAdjustDialog(
        product: p,
        onSaved: () async {
          await _loadProducts();
          if (!mounted) return;
          _exitSelectionMode();
        },
      ),
    );
  }

  Widget _buildSelectionBar(ThemeData theme) {
    final cs = theme.colorScheme;

    return Material(
      color: cs.surface,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              IconButton(
                tooltip: 'inventory.selection.close'.tr(),
                onPressed: _exitSelectionMode,
                icon: const Icon(Icons.close),
              ),
              Expanded(
                child: Text(
                  _selectedCountText(_selectedCount),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              if (_selectedCount == 1) ...[
                IconButton(
                  tooltip: 'action_sheet.edit'.tr(),
                  onPressed: _editSingleSelected,
                  icon: const Icon(Icons.edit),
                ),
                IconButton(
                  tooltip: 'action_sheet.adjust_quantity'.tr(),
                  onPressed: _adjustQuantitySingleSelected,
                  icon: const Icon(Icons.exposure_plus_1),
                ),
              ],
              IconButton(
                tooltip: 'action_sheet.delete'.tr(),
                onPressed: _confirmAndDeleteSelected,
                icon: Icon(Icons.delete, color: cs.error),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );
  }

  String _normalizeFilterKey(String raw) {
    switch (raw) {
      case 'Vše':
        return 'all';

      case 'Lednice':
        return 'fridge';
      case 'Mrazák':
        return 'freezer';
      case 'Spíž':
        return 'pantry';

      case 'Jídlo':
        return 'food';
      case 'Pití':
      case 'Nápoj':
        return 'beverage';
      case 'Ostatní':
        return 'other';

      // expiration labels
      case 'Čerstvé':
        return 'fresh';
      case 'Brzy expiruje':
        return 'soon';
      case 'Dnes expiruje':
        return 'today';
      case 'Prošlé':
        return 'expired';

      default:
        return raw;
    }
  }

  String _normalizeProductCategory(Product p) {
    return _normalizeFilterKey(p.category);
  }

  String _normalizeProductType(Product p) {
    final raw = (p.extra?['type'] ?? 'food').toString();
    return _normalizeFilterKey(raw);
  }

  String _expirationStatus(Product p, {int soonDays = 3}) {
    final d = p.expirationDate;
    if (d == null) {
      return 'fresh';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final exp = DateTime(d.year, d.month, d.day);

    final diff = exp.difference(today).inDays;
    if (diff < 0) return 'expired';
    if (diff == 0) return 'today';
    if (diff >= 1 && diff <= soonDays) return 'soon';
    return 'fresh';
  }

  List<Product> get filteredProducts {
    final selCategory = _normalizeFilterKey(_filterCategory);
    final selType = _normalizeFilterKey(_filterType);
    final selExpiration = _normalizeFilterKey(_filterExpiration);

    return _products.where((p) {
      final matchesSearch = p.name.toLowerCase().contains(
        _search.toLowerCase(),
      );

      final pCategory = _normalizeProductCategory(p);
      final matchesCategory = selCategory == 'all' || pCategory == selCategory;

      final pType = _normalizeProductType(p);
      final matchesType = selType == 'all' || pType == selType;

      final matchesExpiration =
          selExpiration == 'all' || _expirationStatus(p) == selExpiration;

      return matchesSearch &&
          matchesCategory &&
          matchesType &&
          matchesExpiration;
    }).toList();
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
    const statusKeys = {'expired', 'today', 'soon', 'fresh'};
    if (statusKeys.contains(key)) {
      return 'inventory.status.$key'.tr();
    }
    return raw;
  }

  String _getActiveFiltersText() {
    final filters = <String>[];
    if (_filterCategory != 'all') {
      filters.add(_trFilterLabel(_filterCategory));
    }
    if (_filterType != 'all') {
      filters.add(_trFilterLabel(_filterType));
    }
    if (_filterExpiration != 'all') {
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
        _normalizeFilterKey(_filterCategory) != 'all' ||
        _normalizeFilterKey(_filterType) != 'all' ||
        _normalizeFilterKey(_filterExpiration) != 'all';

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

    return WillPopScope(
      onWillPop: () async {
        if (_isSelectionMode) {
          _exitSelectionMode();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: Column(
          children: [
            _isSelectionMode ? _buildSelectionBar(theme) : _buildTopBar(theme),

            if (hasActiveFilters)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
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
                          _filterCategory = 'all';
                          _filterType = 'all';
                          _filterExpiration = 'all';
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
                      itemBuilder: (context, i) {
                        final p = filtered[i];
                        final isSelected = _selectedProducts.contains(p);

                        return ProductList(
                          product: p,
                          onTap: () => _showProductDetail(p),
                          onChanged: _loadProducts,

                          // NEW: multi-select support
                          isSelectionMode: _isSelectionMode,
                          isSelected: isSelected,
                          onSelectChanged: (val) => _toggleSelection(p, val),
                          onLongPress: () {
                            if (_isSelectionMode) {
                              _toggleSelection(p, !isSelected);
                            } else {
                              _enterSelectionMode(p);
                            }
                          },
                        );
                      },
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

        floatingActionButton: _isSelectionMode
            ? null
            : SpeedDial(
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
      ),
    );
  }
}
