import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import 'package:easy_localization/easy_localization.dart';

class SettingsScreen extends StatefulWidget {
  final Function(bool) onThemeChanged;
  final bool currentDarkMode;
  final String currentSeedKey;
  final Function(String) onSeedChanged;

  const SettingsScreen({
    super.key,
    required this.onThemeChanged,
    required this.currentDarkMode,
    required this.currentSeedKey,
    required this.onSeedChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDarkMode = false;
  bool _notificationsEnabled = true;
  int _expirationWarningDays = 3;

  String _languageCode = 'cs';
  bool _haptics = true;
  bool _sounds = false;
  late String _seedKey;

  @override
  void initState() {
    super.initState();
    _seedKey = widget.currentSeedKey;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _isDarkMode = widget.currentDarkMode;
    _notificationsEnabled = await SettingsService.getNotificationsEnabled();
    _expirationWarningDays = await SettingsService.getExpirationWarningDays();

    final code = await SettingsService.getLocaleCode();
    _languageCode = (code ?? context.locale.languageCode);
    _seedKey = await SettingsService.getThemeSeedKey();
    // fallback when coming from main for first build
    _seedKey = _seedKey.isEmpty ? widget.currentSeedKey : _seedKey;

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        title: Text(
          'settings.title'.tr(),
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant.withOpacity(0.6),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          const SizedBox(height: 12),

          _buildSectionBlock(
            theme: theme,
            header: 'settings.appearance.title'.tr(),
            children: [
              _buildSettingRow(
                theme: theme,
                icon: Icons.dark_mode,
                title: 'settings.appearance.dark.title'.tr(),
                subtitle: 'settings.appearance.dark.subtitle'.tr(),
                trailing: Switch(
                  value: _isDarkMode,
                  onChanged: _toggleDarkMode,
                  activeColor: theme.colorScheme.primary,
                  inactiveThumbColor: theme.colorScheme.outline,
                  inactiveTrackColor: theme.colorScheme.outlineVariant
                      .withOpacity(0.5),
                ),
              ),
              _buildSettingRow(
                theme: theme,
                icon: Icons.color_lens_outlined,
                title: 'settings.appearance.theme.primary.title'.tr(),
                subtitle: ('settings.appearance.theme.primary.options.$_seedKey'.tr()),
                onTap: _showSeedDialog,
              ),
              _buildSettingRow(
                theme: theme,
                icon: Icons.language,
                title: 'settings.appearance.language.title'.tr(),
                subtitle: 'settings.appearance.language.$_languageCode'.tr(),
                onTap: _showLanguageDialog,
              ),
            ],
          ),

          const SizedBox(height: 14),

          _buildSectionBlock(
            theme: theme,
            header: 'settings.alerts.title'.tr(),
            children: [
              _buildSettingRow(
                theme: theme,
                icon: Icons.notifications_active,
                title: 'settings.alerts.notifications.title'.tr(),
                subtitle: 'settings.alerts.notifications.subtitle'.tr(),
                trailing: Switch(
                  value: _notificationsEnabled,
                  onChanged: _toggleNotifications,
                  activeColor: theme.colorScheme.primary,
                  inactiveThumbColor: theme.colorScheme.outline,
                  inactiveTrackColor: theme.colorScheme.outlineVariant
                      .withOpacity(0.5),
                ),
              ),
              _buildSettingRow(
                theme: theme,
                icon: Icons.schedule,
                title: 'settings.alerts.expiration.title'.tr(),
                subtitle: _expirationWarningDays == 0
                    ? 'settings.common.off'.tr()
                    : _expirationSubtitle(_expirationWarningDays),
                onTap: _showExpirationDialog,
              ),
            ],
          ),

          const SizedBox(height: 14),

          _buildSectionBlock(
            theme: theme,
            header: 'settings.behavior.title'.tr(),
            children: [
              _buildSettingRow(
                theme: theme,
                icon: Icons.vibration,
                title: 'settings.behavior.haptics.title'.tr(),
                subtitle: 'settings.behavior.haptics.subtitle'.tr(),
                trailing: Switch(
                  value: _haptics,
                  onChanged: (v) => setState(() => _haptics = v),
                  activeColor: theme.colorScheme.primary,
                  inactiveThumbColor: theme.colorScheme.outline,
                  inactiveTrackColor: theme.colorScheme.outlineVariant
                      .withOpacity(0.5),
                ),
              ),
              _buildSettingRow(
                theme: theme,
                icon: Icons.volume_up_outlined,
                title: 'settings.behavior.sounds.title'.tr(),
                subtitle: 'settings.behavior.sounds.subtitle'.tr(),
                trailing: Switch(
                  value: _sounds,
                  onChanged: (v) => setState(() => _sounds = v),
                  activeColor: theme.colorScheme.primary,
                  inactiveThumbColor: theme.colorScheme.outline,
                  inactiveTrackColor: theme.colorScheme.outlineVariant
                      .withOpacity(0.5),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          _buildSectionBlock(
            theme: theme,
            header: 'settings.about.title'.tr(),
            children: [
              _buildSettingRow(
                theme: theme,
                icon: Icons.info_outline,
                title: 'settings.about.info.title'.tr(),
                subtitle: 'settings.about.info.subtitle'.tr(),
                onTap: () => _showComingSoon('settings.about.info.title'.tr()),
              ),
              _buildSettingRow(
                theme: theme,
                icon: Icons.help_outline,
                title: 'settings.about.help.title'.tr(),
                subtitle: 'settings.about.help.subtitle'.tr(),
                onTap: () => _showComingSoon('settings.about.help.title'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------- UI HELPERS ----------------

  Widget _buildSectionBlock({
    required ThemeData theme,
    required String header,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            header,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        Material(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            children: _withDividers(
              children,
              Divider(
                height: 1,
                thickness: 1,
                indent: 16,
                endIndent: 16,
                color: theme.colorScheme.outlineVariant.withOpacity(0.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _withDividers(List<Widget> items, Widget divider) {
    final out = <Widget>[];
    for (int i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i != items.length - 1) out.add(divider);
    }
    return out;
  }

  Widget _buildSettingRow({
    required ThemeData theme,
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final hasTap = onTap != null;

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: trailing ?? (hasTap ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      visualDensity: const VisualDensity(horizontal: 0, vertical: -1),
    );
  }

  // ---------------- DIALOGS ----------------

  void _showComingSoon(String featureName) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          featureName,
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Text(
          'settings.about.coming_soon'.tr(),
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'settings.common.ok'.tr(),
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    final theme = Theme.of(context);
    final options = ['cs', 'en', 'de'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'settings.appearance.language.dialog_title'.tr(),
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (o) => RadioListTile<String>(
                  value: o,
                  groupValue: _languageCode,
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => _languageCode = v);
                    await SettingsService.setLocaleCode(v);
                    await context.setLocale(Locale(v));
                    if (mounted) Navigator.pop(context);
                  },
                  activeColor: theme.colorScheme.primary,
                  title: Text(
                    'settings.appearance.language.$o'.tr(),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _showExpirationDialog() {
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'settings.alerts.expiration.dialog_title'.tr(),
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final days in [1, 3, 5, 7])
              RadioListTile<int>(
                title: Text(
                  _expirationSubtitle(days),
                  style: TextStyle(color: theme.colorScheme.onSurface),
                ),
                value: days,
                groupValue: _expirationWarningDays,
                onChanged: (value) {
                  if (value == null) return;
                  _setExpirationDays(value);
                  Navigator.pop(context);
                },
                activeColor: theme.colorScheme.primary,
              ),
            RadioListTile<int>(
              title: Text(
                'settings.common.off'.tr(),
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              value: 0,
              groupValue: _expirationWarningDays,
              onChanged: (value) {
                if (value == null) return;
                _setExpirationDays(value);
                Navigator.pop(context);
              },
              activeColor: theme.colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  void _showSeedDialog() {
    final theme = Theme.of(context);
    const options = ['green', 'blue', 'purple', 'orange', 'pink'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'settings.appearance.theme.primary.dialog_title'.tr(),
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options
              .map(
                (k) => RadioListTile<String>(
                  value: k,
                  groupValue: _seedKey,
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => _seedKey = v);
                    await SettingsService.setThemeSeedKey(v);
                    widget.onSeedChanged(v);
                    if (mounted) Navigator.pop(context);
                  },
                  activeColor: theme.colorScheme.primary,
                  title: Text(
                    'settings.appearance.theme.primary.options.$k'.tr(),
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  String _expirationSubtitle(int days) {
    if (context.locale.languageCode == 'cs') {
      if (days == 1) return '1 den před expirací';
      if (days >= 2 && days <= 4) return '$days dny před expirací';
      return '$days dní před expirací';
    }

    return 'settings.alerts.expiration.before'.plural(
      days,
      namedArgs: {'count': '$days'},
    );
  }
}
