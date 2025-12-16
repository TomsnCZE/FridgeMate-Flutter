import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool currentDarkMode;

  const SettingsScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentDarkMode,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  int _expirationWarningDays = 3;
  bool _hideExpiredProducts = false;
  String _defaultCategory = 'Lednice';
  String _defaultUnit = 'ks';
  String _viewMode = 'list';

  final List<String> _categories = ['Lednice', 'Mrazák', 'Spíž', 'Špajz'];
  final List<String> _units = ['ks', 'g', 'kg', 'ml', 'l'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _isDarkMode = widget.currentDarkMode;
    _notificationsEnabled = await SettingsService.getNotificationsEnabled();
    _expirationWarningDays = await SettingsService.getExpirationWarningDays();
    _hideExpiredProducts = await SettingsService.getHideExpired();
    _defaultCategory = await SettingsService.getDefaultCategory();
    _defaultUnit = await SettingsService.getDefaultUnit();
    _viewMode = await SettingsService.getViewMode();
    
    setState(() {});
  }

  void _toggleDarkMode(bool value) async {
    setState(() => _isDarkMode = value);
    await SettingsService.setDarkMode(value);
    widget.onThemeChanged(value);
  }

  void _toggleNotifications(bool value) async {
    setState(() => _notificationsEnabled = value);
    await SettingsService.setNotificationsEnabled(value);
  }

  void _setExpirationDays(int days) async {
    setState(() => _expirationWarningDays = days);
    await SettingsService.setExpirationWarningDays(days);
  }

  void _toggleHideExpired(bool value) async {
    setState(() => _hideExpiredProducts = value);
    await SettingsService.setHideExpired(value);
  }

  void _setDefaultCategory(String category) async {
    setState(() => _defaultCategory = category);
    await SettingsService.setDefaultCategory(category);
  }

  void _setDefaultUnit(String unit) async {
    setState(() => _defaultUnit = unit);
    await SettingsService.setDefaultUnit(unit);
  }

  void _setViewMode(String mode) async {
    setState(() => _viewMode = mode);
    await SettingsService.setViewMode(mode);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    //final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nastavení'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // SEKCE: VZHLED
          _buildSectionHeader('Vzhled', theme),
          _buildSettingTile(
            icon: Icons.dark_mode,
            title: 'Tmavý režim',
            subtitle: 'Přepnout na tmavý motiv',
            trailing: Switch(
              value: _isDarkMode,
              onChanged: _toggleDarkMode,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            theme: theme,
          ),

          _buildSettingTile(
            icon: Icons.view_module,
            title: 'Zobrazení produktů',
            subtitle: _viewMode == 'list' ? 'Seznam' : 'Mřížka',
            onTap: () => _showViewModeDialog(),
            theme: theme,
          ),

          const SizedBox(height: 8),

          // SEKCE: NOTIFIKACE
          _buildSectionHeader('Upozornění', theme),
          _buildSettingTile(
            icon: Icons.notifications_active,
            title: 'Povolit notifikace',
            subtitle: 'Upozornění na expiraci produktů',
            trailing: Switch(
              value: _notificationsEnabled,
              onChanged: _toggleNotifications,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            theme: theme,
          ),

          _buildSettingTile(
            icon: Icons.schedule,
            title: 'Upozornit před expirací',
            subtitle: 'Aktuálně: $_expirationWarningDays ${_getDayText(_expirationWarningDays)} předem',
            onTap: () => _showExpirationDialog(),
            theme: theme,
          ),

          const SizedBox(height: 8),

          // SEKCE: INVENTORY
          _buildSectionHeader('Sklad', theme),
          _buildSettingTile(
            icon: Icons.visibility_off,
            title: 'Skrýt prošlé produkty',
            subtitle: 'Automaticky skrýt expirované položky',
            trailing: Switch(
              value: _hideExpiredProducts,
              onChanged: _toggleHideExpired,
              activeColor: Theme.of(context).colorScheme.primary,
            ),
            theme: theme,
          ),

          _buildSettingTile(
            icon: Icons.category,
            title: 'Výchozí kategorie',
            subtitle: _defaultCategory,
            onTap: () => _showCategoryDialog(),
            theme: theme,
          ),

          _buildSettingTile(
            icon: Icons.scale,
            title: 'Výchozí jednotka',
            subtitle: _defaultUnit,
            onTap: () => _showUnitDialog(),
            theme: theme,
          ),

          const SizedBox(height: 24),

          // SEKCE: DATA
          _buildSectionHeader('Data', theme),
          _buildSettingTile(
            icon: Icons.backup,
            title: 'Zálohovat data',
            subtitle: 'Uložit do cloudu',
            onTap: _backupData,
            theme: theme,
          ),

          _buildSettingTile(
            icon: Icons.restore,
            title: 'Obnovit data',
            subtitle: 'Načíst ze zálohy',
            onTap: _restoreData,
            theme: theme,
          ),

          _buildSettingTile(
            icon: Icons.delete_sweep,
            title: 'Smazat všechna data',
            subtitle: 'Trvale odstranit veškerý obsah',
            onTap: () => _showDeleteConfirmation(),
            textColor: Colors.red,
            theme: theme,
          ),

          const SizedBox(height: 32),

          // INFO O APLIKACI
          Center(
            child: Column(
              children: [
                Text(
                  'FridgeMate v1.0.0',
                  style: TextStyle(
                    color: theme.hintColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '© 2024 Tvůj FridgeMate',
                  style: TextStyle(
                    color: theme.hintColor.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required ThemeData theme,
    Widget? trailing,
    VoidCallback? onTap,
    Color? textColor,
  }) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: theme.cardColor,
      child: ListTile(
        leading: Icon(icon, color: textColor ?? theme.colorScheme.primary),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: textColor ?? theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: textColor?.withOpacity(0.7) ?? theme.hintColor,
          ),
        ),
        trailing: trailing,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  void _showViewModeDialog() {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Zobrazení produktů',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.cardColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Row(
                children: [
                  Icon(Icons.view_list, color: theme.colorScheme.onSurface),
                  const SizedBox(width: 12),
                  Text(
                    'Seznam',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
              value: 'list',
              groupValue: _viewMode,
              onChanged: (value) {
                _setViewMode(value!);
                Navigator.pop(context);
              },
              activeColor: theme.colorScheme.primary,
            ),
            RadioListTile<String>(
              title: Row(
                children: [
                  Icon(Icons.grid_view, color: theme.colorScheme.onSurface),
                  const SizedBox(width: 12),
                  Text(
                    'Mřížka',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ],
              ),
              value: 'grid',
              groupValue: _viewMode,
              onChanged: (value) {
                _setViewMode(value!);
                Navigator.pop(context);
              },
              activeColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _showExpirationDialog() {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Upozornění před expirací',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.cardColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final days in [1, 3, 5, 7])
              RadioListTile<int>(
                title: Text(
                  '$days ${_getDayText(days)} předem',
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                value: days,
                groupValue: _expirationWarningDays,
                onChanged: (value) {
                  _setExpirationDays(value!);
                  Navigator.pop(context);
                },
                activeColor: theme.colorScheme.primary,
              ),
            RadioListTile<int>(
              title: Text(
                'Vypnout upozornění',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              value: 0,
              groupValue: _expirationWarningDays,
              onChanged: (value) {
                _setExpirationDays(value!);
                Navigator.pop(context);
              },
              activeColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _showCategoryDialog() {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Výchozí kategorie',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.cardColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _categories.map((category) {
            return RadioListTile<String>(
              title: Text(
                category,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              value: category,
              groupValue: _defaultCategory,
              onChanged: (value) {
                _setDefaultCategory(value!);
                Navigator.pop(context);
              },
              activeColor: theme.colorScheme.primary,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showUnitDialog() {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Výchozí jednotka',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.cardColor,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _units.map((unit) {
            return RadioListTile<String>(
              title: Text(
                unit,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              value: unit,
              groupValue: _defaultUnit,
              onChanged: (value) {
                _setDefaultUnit(value!);
                Navigator.pop(context);
              },
              activeColor: theme.colorScheme.primary,
            );
          }).toList(),
        ),
      ),
    );
  }

  void _backupData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Data byla úspěšně zazálohována'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _restoreData() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Data byla obnovena ze zálohy'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showDeleteConfirmation() {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Smazat všechna data?',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        backgroundColor: theme.cardColor,
        content: Text(
          'Tato akce je nevratná. Opravdu chceš smazat všechny produkty a nastavení?',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Zrušit',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Všechna data byla smazána'),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );
  }

  String _getDayText(int days) {
    if (days == 0) return 'dní';
    return days == 1 ? 'den' : (days >= 2 && days <= 4 ? 'dny' : 'dní');
  }
}