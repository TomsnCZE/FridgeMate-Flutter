import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../widgets/product_detail_bottom_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  bool _loading = true;
  int _warningDays = 3;
  int get _soonWindowDays => _warningDays == 0 ? 3 : _warningDays;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // první load
    _load();

    // iOS: po prvním vykreslení to často chytne správný stav (db + prefs)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load(force: true);
    });
  }

Future<void> _load({bool force = false}) async {
    try {
      final data = await DatabaseService.instance.getAllProducts();
      final products = data.map((e) => Product.fromMap(e)).toList();

      if (!mounted) return;
      setState(() {
        _products = products;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  int? _daysToExpiration(DateTime? d) {
    if (d == null) return null;
    final dd = DateTime(d.year, d.month, d.day);
    return dd.difference(_today).inDays;
  }

  int get _totalCount => _products.length;

  int get _expiredCount {
    return _products.where((p) {
      final diff = _daysToExpiration(p.expirationDate);
      return diff != null && diff < 0;
    }).length;
  }

  int get _expiringSoonCount {
    return _products.where((p) {
      final diff = _daysToExpiration(p.expirationDate);
      return diff != null && diff >= 0 && diff <= _soonWindowDays;
    }).length;
  }

  List<Product> get _expiringSoonList {
    final list = _products.where((p) {
      final diff = _daysToExpiration(p.expirationDate);
      return diff != null && diff >= 0 && diff <= _soonWindowDays;
    }).toList();

    list.sort((a, b) {
      final da = a.expirationDate;
      final db = b.expirationDate;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });
    return list;
  }

  List<Product> get _expiredList {
    final list = _products.where((p) {
      final diff = _daysToExpiration(p.expirationDate);
      return diff != null && diff < 0;
    }).toList();

    list.sort((a, b) {
      final da = a.expirationDate;
      final db = b.expirationDate;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return db.compareTo(da);
    });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _StatusBar(
            total: _totalCount,
            soon: _expiringSoonCount,
            expired: _expiredCount,
          ),
          const SizedBox(height: 16),

          if (_expiringSoonCount > 0) ...[
            _SectionCard(
              title: 'home.warning.title'.tr(),
              icon: Icons.schedule,
              children: _expiringSoonList
                  .take(5)
                  .map(
                    (p) =>
                        _ProductRow(product: p, warningDays: _soonWindowDays),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          if (_expiredCount > 0) ...[
            _SectionCard(
              title: 'home.stats.expired'.tr(),
              icon: Icons.warning_amber_rounded,
              iconColor: cs.error,
              children: _expiredList
                  .take(3)
                  .map(
                    (p) => _ProductRow(product: p, warningDays: _warningDays),
                  )
                  .toList(),
            ),
          ],

          if (_expiringSoonCount == 0 && _expiredCount == 0) ...[
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _StatusBar extends StatelessWidget {
  final int total;
  final int soon;
  final int expired;

  const _StatusBar({
    required this.total,
    required this.soon,
    required this.expired,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    Widget item({required int value, required String label, Color? accent}) {
      return Expanded(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value.toString(),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: accent ?? cs.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.6)),
      ),
      child: Row(
        children: [
          item(value: total, label: 'home.stats.total_products'.tr()),
          _divider(cs),
          item(
            value: soon,
            label: 'home.stats.expiring_soon'.tr(),
            accent: soon > 0 ? cs.primary : cs.onSurface,
          ),
          _divider(cs),
          item(
            value: expired,
            label: 'home.stats.expired'.tr(),
            accent: expired > 0 ? cs.error : cs.onSurface,
          ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme cs) {
    return Container(
      width: 1,
      height: 36,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: cs.outlineVariant.withOpacity(0.5),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color? iconColor;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Row(
              children: [
                Icon(icon, size: 18, color: iconColor ?? cs.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: cs.outlineVariant.withOpacity(0.4)),
          ...children,
        ],
      ),
    );
  }
}

String _normalizeCategoryKey(dynamic raw) {
  final v = (raw ?? '').toString().trim();

  // already a key
  if (v == 'fridge' || v == 'freezer' || v == 'pantry') return v;

  // CZ legacy
  if (v == 'Lednice') return 'fridge';
  if (v == 'Mrazák' || v == 'Mrazak') return 'freezer';
  if (v == 'Spíž' || v == 'Spiz') return 'pantry';

  // EN legacy
  if (v == 'Fridge') return 'fridge';
  if (v == 'Freezer') return 'freezer';
  if (v == 'Pantry') return 'pantry';

  // DE legacy
  if (v == 'Kühlschrank' || v == 'Kuehlschrank') return 'fridge';
  if (v == 'Gefrierschrank') return 'freezer';
  if (v == 'Vorratskammer' || v == 'Speisekammer') return 'pantry';

  return 'fridge';
}

class _ProductRow extends StatelessWidget {
  final Product product;
  final int warningDays;

  const _ProductRow({required this.product, required this.warningDays});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final d = product.expirationDate;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = d == null
        ? null
        : DateTime(d.year, d.month, d.day).difference(today).inDays;

    String trailing;
    Color trailingColor = cs.onSurfaceVariant;

    if (diff == null) {
      trailing = '—';
    } else if (diff < 0) {
      trailing = '${d!.day}.${d.month}.${d.year}';
      trailingColor = cs.error;
    } else if (diff == 0) {
      trailing = 'inventory.status.today'.tr();
      trailingColor = cs.primary;
    } else {
      trailing = '${diff}d';
      trailingColor = diff <= warningDays ? cs.primary : cs.onSurfaceVariant;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (context) => ProductDetailBottomSheet(product: product),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'add_product.${_normalizeCategoryKey(product.category)}'
                        .tr(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                trailing,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: trailingColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right, color: cs.onSurfaceVariant, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
