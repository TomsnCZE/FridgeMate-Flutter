import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class FilterBottomSheet extends StatefulWidget {
  final String currentCategory;
  final String currentType;
  final String currentExpiration;
  final Function(String, String, String) onFiltersChanged;

  const FilterBottomSheet({
    super.key,
    required this.currentCategory,
    required this.currentType,
    required this.currentExpiration,
    required this.onFiltersChanged,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String _selectedCategory;
  late String _selectedType;
  late String _selectedExpiration;

  final List<String> _categories = ['all', 'fridge', 'freezer', 'pantry'];
  final List<String> _types = ['all', 'food', 'beverage', 'other'];
  final List<String> _expirations = ['all', 'fresh', 'soon', 'expired', 'today'];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.currentCategory;
    _selectedType = widget.currentType;
    _selectedExpiration = widget.currentExpiration;
  }

  void _applyFilters() {
    widget.onFiltersChanged(_selectedCategory, _selectedType, _selectedExpiration);
    Navigator.pop(context);
  }

  void _resetFilters() {
    setState(() {
      _selectedCategory = 'all';
      _selectedType = 'all';
      _selectedExpiration = 'all';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [       
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'inventory.filters.title'.tr(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // FILTR PODLE KATEGORIE
          _buildFilterSection(
            title: 'inventory.filters.category'.tr(),
            options: _categories,
            selected: _selectedCategory,
            onChanged: (value) => setState(() => _selectedCategory = value),
            theme: theme,
          ),

          const SizedBox(height: 16),

          // FILTR PODLE TYPU
          _buildFilterSection(
            title: 'inventory.filters.type'.tr(),
            options: _types,
            selected: _selectedType,
            onChanged: (value) => setState(() => _selectedType = value),
            theme: theme,
          ),

          const SizedBox(height: 16),

          // FILTR PODLE EXPIRACE
          _buildFilterSection(
            title: 'inventory.filters.expiration'.tr(),
            options: _expirations,
            selected: _selectedExpiration,
            onChanged: (value) => setState(() => _selectedExpiration = value),
            theme: theme,
          ),

          const SizedBox(height: 24),

          // TLAČÍTKA
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _resetFilters,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: theme.dividerColor),
                  ),
                  child: Text(
                    'inventory.filters.reset'.tr(),
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _applyFilters,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('inventory.filters.apply'.tr()),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _labelForOption(String key) {
    switch (key) {
      // common
      case 'all':
        return 'common.all';

      // categories (locations)
      case 'fridge':
        return 'add_product.fridge';
      case 'freezer':
        return 'add_product.freezer';
      case 'pantry':
        return 'add_product.pantry';

      // types
      case 'food':
        return 'add_product.food';
      case 'beverage':
        return 'add_product.beverage';
      case 'other':
        return 'add_product.other';

      // expiration filters
      case 'fresh':
        return 'inventory.filters.expiration_fresh';
      case 'soon':
        return 'inventory.filters.expiration_soon';
      case 'today':
        return 'inventory.filters.expiration_today';
      case 'expired':
        return 'inventory.filters.expiration_expired';

      default:
        return key;
    }
  }

  Widget _buildFilterSection({
    required String title,
    required List<String> options,
    required String selected,
    required Function(String) onChanged,
    required ThemeData theme,
  }) {

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: options.map((option) {
            final isSelected = selected == option;
            return FilterChip(
              label: Text(_labelForOption(option).tr()),
              selected: isSelected,
              onSelected: (selected) => onChanged(option),
              backgroundColor: theme.colorScheme.surfaceVariant,
              selectedColor: theme.colorScheme.primary.withOpacity(0.2),
              checkmarkColor: theme.brightness == Brightness.dark ? Colors.white : theme.colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected
                    ? (theme.brightness == Brightness.dark
                        ? Colors.white
                        : theme.colorScheme.onSurface)
                    : theme.colorScheme.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}