import 'package:flutter/material.dart';

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

  final List<String> _categories = ['Vše', 'Lednice', 'Mrazák', 'Spíž'];
  final List<String> _types = ['Vše', 'Jídlo', 'Pití', 'Ostatní'];
  final List<String> _expirations = ['Vše', 'Čerstvé', 'Brzy expiruje', 'Prošlé', 'Dnes expiruje'];

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
      _selectedCategory = 'Vše';
      _selectedType = 'Vše';
      _selectedExpiration = 'Vše';
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
                'Filtrovat produkty',
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
            title: 'Kategorie',
            options: _categories,
            selected: _selectedCategory,
            onChanged: (value) => setState(() => _selectedCategory = value),
            theme: theme,
          ),

          const SizedBox(height: 16),

          // FILTR PODLE TYPU
          _buildFilterSection(
            title: 'Typ produktu',
            options: _types,
            selected: _selectedType,
            onChanged: (value) => setState(() => _selectedType = value),
            theme: theme,
          ),

          const SizedBox(height: 16),

          // FILTR PODLE EXPIRACE
          _buildFilterSection(
            title: 'Stav expirace',
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
                    'Resetovat',
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
                  child: const Text('Použít filtry'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
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
              label: Text(option),
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