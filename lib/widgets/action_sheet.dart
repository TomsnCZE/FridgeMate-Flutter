import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/database_service.dart';
import '../screens/product_edit_screen.dart';

class ProductActionSheet extends StatelessWidget {
  final Product product;
  final BuildContext parentContext;
  final VoidCallback onChanged;

  const ProductActionSheet({
    super.key,
    required this.product,
    required this.parentContext,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),

            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.swap_vert),
              title: const Text('Upravit množství'),
              onTap: () {
                // zavře sheet a otevře dialog nad parentContext
                Navigator.pop(context);
                showDialog(
                  context: parentContext,
                  builder: (_) => QuantityAdjustDialog(
                    product: product,
                    onSaved: onChanged,
                  ),
                );
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),

            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Upravit'),
              onTap: () async {
                Navigator.pop(context); // zavře sheet

                final result = await Navigator.push(
                  parentContext,
                  MaterialPageRoute(
                    builder: (_) => EditProductScreen(product: product),
                  ),
                );

                if (result != null) {
                  onChanged();
                }
              },
            ),
            const Divider(height: 1, indent: 16, endIndent: 16),

            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Smazat', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Smazat produkt?'),
                    content: Text('Opravdu chceš smazat "${product.name}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Zrušit'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Smazat'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && product.id != null) {
                  await DatabaseService.instance.deleteProduct(product.id!);
                  Navigator.pop(context); // zavře sheet
                  onChanged();
                }
              },
            ),

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class QuantityAdjustDialog extends StatefulWidget {
  final Product product;
  final VoidCallback onSaved;

  const QuantityAdjustDialog({
    super.key,
    required this.product,
    required this.onSaved,
  });

  @override
  State<QuantityAdjustDialog> createState() => _QuantityAdjustDialogState();
}

class _QuantityAdjustDialogState extends State<QuantityAdjustDialog>
    with SingleTickerProviderStateMixin {
  // Removed: bool _isAdd = false; // default: Odebrat
  // Removed: double _delta = 0;
  // Removed: late final TextEditingController _deltaController;
  // Keep _step
  double _step = 1;

  double _current = 0;
  double _result = 0;
  Timer? _holdTimer;
  int _holdMs = 220;
  int _holdDir = 0;

  late final AnimationController _chevronCtrl;

  @override
  void initState() {
    super.initState();

    final unit = (widget.product.extra?['unit'] ?? 'ks').toString();

    // rozumný default kroku podle jednotky
    if (unit == 'ks') {
      _step = 1;
    } else if (unit == 'g' || unit == 'ml') {
      _step = 10;
    } else if (unit == 'l' || unit == 'kg') {
      _step = 0.1;
    } else {
      _step = 1;
    }

    final decimals = _decimalsForUnit(unit);
    _current = decimals == 0
        ? widget.product.quantity.roundToDouble()
        : widget.product.quantity;
    _result = _current;

    _chevronCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    );
  }

  @override
  void dispose() {
    _stopHold();
    _chevronCtrl.dispose();
    super.dispose();
  }

  int _decimalsForUnit(String unit) {
    if (unit == 'l' || unit == 'kg') return 2; // umožní 0.5 / 0.25 apod.
    return 0; // ks, g, ml – celočíselně
  }

  String _formatDelta(String unit, double value) {
    final d = _decimalsForUnit(unit);
    if (d == 0) return value.round().toString();

    // Keep up to `d` decimals, then trim trailing zeros and possible trailing dot.
    String s = value.toStringAsFixed(d);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '');
      s = s.replaceFirst(RegExp(r'\.$'), '');
    }
    return s;
  }

  List<double> _stepOptionsForUnit(String unit) {
    switch (unit) {
      case 'ks':
        return const [1, 2, 5, 10];
      case 'g':
      case 'ml':
        return const [1, 2, 5, 10, 25, 50, 100, 250];
      case 'kg':
      case 'l':
        return const [0.1, 0.25, 0.5, 1, 2];
      default:
        return const [1, 2, 5, 10];
    }
  }

  void _applyStep(int direction) {
    final unit = (widget.product.extra?['unit'] ?? 'ks').toString();
    final decimals = _decimalsForUnit(unit);

    double next = _result + (direction * _step);
    if (next < 0) next = 0;

    if (decimals == 0) {
      next = next.roundToDouble();
    } else {
      final factor = 100;
      next = (next * factor).round() / factor;
    }

    setState(() => _result = next);
  }

  void _startHold(int direction) {
    _stopHold();
    _holdDir = direction;
    _holdMs = 220;

    // okamžitě aplikuj 1 krok
    _applyStep(direction);

    // pak se opakovaně zrychluj
    _scheduleNextHoldTick();
  }

  void _scheduleNextHoldTick() {
    _holdTimer = Timer(Duration(milliseconds: _holdMs), () {
      _applyStep(_holdDir);

      // zrychlení – postupně zkracuj interval, ale drž minimální limit
      if (_holdMs > 60) {
        _holdMs = (_holdMs * 0.85).round();
        if (_holdMs < 60) _holdMs = 60;
      }

      // pokračuj, dokud držíme
      _scheduleNextHoldTick();
    });
  }

  void _stopHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
    _holdDir = 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unit = (widget.product.extra?['unit'] ?? 'ks').toString();

    final steps = _stepOptionsForUnit(unit);
    if (!steps.contains(_step)) {
      _step = steps.first;
    }

    return AlertDialog(
      backgroundColor: theme.cardColor,
      title: Row(
        children: [
          Icon(Icons.swap_vert, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          const Text('Upravit množství'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Summary card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.18),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aktuálně',
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDelta(unit, _current)} $unit',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                Divider(height: 1, color: theme.dividerColor),
                const SizedBox(height: 10),
                Text(
                  'Výsledek',
                  style: theme.textTheme.labelLarge?.copyWith(color: theme.hintColor),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatDelta(unit, _result)} $unit',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 14),

          // Krok (dropdown bez shadow + animovaná šipka)
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withOpacity(0.8)),
            ),
            child: PopupMenuButton<double>(
              tooltip: 'Vybrat krok',
              elevation: 0, // žádný stín
              color: theme.cardColor,
              splashRadius: 18,
              onOpened: () => _chevronCtrl.forward(),
              onCanceled: () => _chevronCtrl.reverse(),
              onSelected: (v) {
                setState(() => _step = v);
                _chevronCtrl.reverse();
              },
              itemBuilder: (context) => [
                for (final s in steps)
                  PopupMenuItem<double>(
                    value: s,
                    child: Text('${_formatDelta(unit, s)} $unit'),
                  ),
              ],
              child: Row(
                children: [
                  Icon(Icons.tune, size: 18, color: theme.colorScheme.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Krok: ${_formatDelta(unit, _step)} $unit',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  RotationTransition(
                    turns: Tween<double>(begin: 0.0, end: 0.5).animate(
                      CurvedAnimation(parent: _chevronCtrl, curve: Curves.easeOut),
                    ),
                    child: Icon(
                      Icons.keyboard_arrow_down,
                      color: theme.hintColor,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(
                child: _HoldButton(
                  icon: Icons.remove,
                  label: 'Odebrat',
                  onTap: () => _applyStep(-1),
                  onHoldStart: () => _startHold(-1),
                  onHoldEnd: _stopHold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HoldButton(
                  icon: Icons.add,
                  label: 'Přidat',
                  onTap: () => _applyStep(1),
                  onHoldStart: () => _startHold(1),
                  onHoldEnd: _stopHold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Text(
            'Tip: podrž + / − pro rychlejší změnu',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.hintColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Zrušit'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (widget.product.id == null) return;

            await DatabaseService.instance.updateProduct(
              widget.product.id!,
              {'quantity': _result},
            );

            if (!mounted) return;
            Navigator.pop(context);
            widget.onSaved();
          },
          child: const Text('Uložit'),
        ),
      ],
    );
  }
}

class _HoldButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final VoidCallback onHoldStart;
  final VoidCallback onHoldEnd;

  const _HoldButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.onHoldStart,
    required this.onHoldEnd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      onLongPressStart: (_) => onHoldStart(),
      onLongPressEnd: (_) => onHoldEnd(),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.colorScheme.primary.withOpacity(0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
