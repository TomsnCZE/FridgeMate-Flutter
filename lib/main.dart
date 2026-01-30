import 'package:flutter/material.dart';

import 'screens/inventory_screen.dart';
import 'screens/settings_screen.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'screens/about_screen.dart';
import 'themes/app_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  off.OpenFoodAPIConfiguration.userAgent = off.UserAgent(name: 'Fridge Mate');
  off.OpenFoodAPIConfiguration.globalLanguages = [
    off.OpenFoodFactsLanguage.CZECH,
  ];

  final savedLocaleCode = await SettingsService.getLocaleCode();
  final startLocale = savedLocaleCode == null ? null : Locale(savedLocaleCode);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('cs'), Locale('en'), Locale('de')],
      path: 'assets/translations',
      fallbackLocale: const Locale('cs'),
      startLocale: startLocale,
      child: const FridgeMateApp(),
    ),
  );
}

class FridgeMateApp extends StatefulWidget {
  const FridgeMateApp({super.key});

  @override
  State<FridgeMateApp> createState() => _FridgeMateAppState();
}

class _FridgeMateAppState extends State<FridgeMateApp> {
  bool _isDarkMode = false;
  String _seedKey = 'green';
  @override
  void initState() {
    super.initState();
    _loadThemeSetting();
  }

Future<void> _loadThemeSetting() async {
  final dark = await SettingsService.getDarkMode();
  final seedKey = await SettingsService.getThemeSeedKey();

  setState(() {
    _isDarkMode = dark;
    _seedKey = seedKey;
  });
}

  void _toggleDarkMode(bool value) async {
    await SettingsService.setDarkMode(value);
    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final seed = AppTheme.seedFromKey(_seedKey);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fridge Mate',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.light(seedColor: seed),
      darkTheme: AppTheme.dark(seedColor: seed),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(
        isDarkMode: _isDarkMode,
        onThemeChanged: _toggleDarkMode,
        currentSeedKey: _seedKey,
        onSeedChanged: (k) {
          setState(() => _seedKey = k);
        },
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final String currentSeedKey;
  final ValueChanged<String> onSeedChanged;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.currentSeedKey,
    required this.onSeedChanged,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tabIndex = 0;

  final int _totalProducts = 24;
  final int _expiringSoonCount = 3;
  final int _expiredCount = 1;
  final int _weeklyConsumed = 8;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [_buildHomeScreen(), const InventoryScreen()];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          //preklad
          _tabIndex == 0 ? 'home.title'.tr() : 'inventory.title'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: false,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 2,
        shadowColor: Colors.black.withOpacity(0.08),
        shape: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.18),
            width: 1,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'menu.title'.tr(),
            elevation: 10,
            offset: const Offset(0, 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            color: Theme.of(context).colorScheme.surface,
            constraints: const BoxConstraints(minWidth: 220),
            onSelected: (value) {
              switch (value) {
                case 'settings':
                  _openSettingsScreen(context);
                  break;
                case 'about':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AboutScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: 'settings',
                height: 48,
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: const Icon(Icons.settings),
                  title: Text('menu.settings'.tr()),
                ),
              ),
              const PopupMenuDivider(
                height: 1,
                color: Color.fromRGBO(153, 153, 153, 0.102),
              ),
              PopupMenuItem<String>(
                value: 'about',
                height: 48,
                child: ListTile(
                  dense: true,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: const Icon(Icons.info_outline),
                  title: Text('menu.about'.tr()),
                ),
              ),
            ],
          ),
        ],
      ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: pages[_tabIndex],
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor.withOpacity(0.2),
              width: 1,
            ),
          ),
        ),
        child: NavigationBar(
          height: 64,
          selectedIndex: _tabIndex,
          onDestinationSelected: (index) => setState(() => _tabIndex = index),
          indicatorColor: Theme.of(
            context,
          ).colorScheme.primary.withOpacity(0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined, size: 22),
              selectedIcon: const Icon(Icons.home, size: 22),
              label: 'nav.home'.tr(),
            ),
            NavigationDestination(
              icon: const Icon(Icons.inventory_2_outlined, size: 22),
              selectedIcon: const Icon(Icons.inventory_2, size: 22),
              label: 'nav.inventory'.tr(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeScreen() {
    final isDarkMode = widget.isDarkMode;
    final hasExpiringProducts = _expiringSoonCount > 0 || _expiredCount > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // 1. STATISTIKY - 4 karty
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildStatCard(
                'home.stats.total_products'.tr(),
                _totalProducts,
                Icons.inventory_2,
                isDarkMode,
              ),
              _buildStatCard(
                'home.stats.expiring_soon'.tr(),
                _expiringSoonCount,
                Icons.warning,
                isDarkMode,
              ),
              _buildStatCard(
                'home.stats.expired'.tr(),
                _expiredCount,
                Icons.error,
                isDarkMode,
              ),
              _buildStatCard(
                'home.stats.consumed'.tr(),
                _weeklyConsumed,
                Icons.analytics,
                isDarkMode,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // 2. UPOZORNĚNÍ
          if (hasExpiringProducts) _buildWarningPanel(isDarkMode),

          const SizedBox(height: 20),

          // 3. RYCHLÉ AKCE
          _buildQuickActions(isDarkMode),

          const SizedBox(height: 20),

          // 4. RYCHLÝ PŘÍSTUP
          _buildQuickAccess(isDarkMode),

          const SizedBox(height: 20),

          // 5. AKTIVITA
          _buildRecentActivity(isDarkMode),

          const SizedBox(height: 20),

          // 6. DOPORUČENÍ
          _buildRecommendations(isDarkMode),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    int count,
    IconData icon,
    bool isDarkMode,
  ) {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningPanel(bool isDarkMode) {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.surfaceVariant,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange[700]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'home.warning.title'.tr(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'home.warning.expiring'.tr(
                      namedArgs: {'count': _expiringSoonCount.toString()},
                    ),
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _tabIndex = 1);
              },
              child: Text('home.warning.view'.tr()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'home.quick_actions.title'.tr(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                'home.quick_actions.add_manual'.tr(),
                Icons.add,
                () {
                  // Otevře přidání produktu
                },
                isDarkMode,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'home.quick_actions.scan_qr'.tr(),
                Icons.qr_code_scanner,
                () {
                  // Otevře QR scanner
                },
                isDarkMode,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'home.quick_actions.quick_pick'.tr(),
                Icons.category,
                () {
                  // Otevře rychlý výběr
                },
                isDarkMode,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    VoidCallback onTap,
    bool isDarkMode,
  ) {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 24,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(height: 8),
              Text(
                text,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAccess(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'home.quick_access.title'.tr(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildQuickAccessCard(
              'home.quick_access.shopping_list'.tr(),
              Icons.shopping_cart,
              isDarkMode,
            ),
            _buildQuickAccessCard(
              'home.quick_access.stats'.tr(),
              Icons.bar_chart,
              isDarkMode,
            ),
            _buildQuickAccessCard(
              'home.quick_access.recipes'.tr(),
              Icons.restaurant_menu,
              isDarkMode,
            ),
            _buildQuickAccessCard(
              'home.quick_access.settings'.tr(),
              Icons.settings,
              isDarkMode,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(String title, IconData icon, bool isDarkMode) {
    return Card(
      elevation: 2,
      color: Theme.of(context).colorScheme.surface,
      child: InkWell(
        onTap: () {
          // Otevře příslušnou obrazovku
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivity(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'home.recent_activity.title'.tr(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Zatím placeholder - později reálná data
                Text(
                  'home.recent_activity.empty'.tr(),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'home.recommendations.title'.tr(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 2,
          color: Theme.of(context).colorScheme.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Zatím placeholder - později chytré tipy
                Text(
                  'home.recommendations.empty'.tr(),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openSettingsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SettingsScreen(
          onThemeChanged: widget.onThemeChanged,
          currentDarkMode: widget.isDarkMode,
          currentSeedKey: widget.currentSeedKey,
          onSeedChanged: widget.onSeedChanged,
        ),
      ),
    );
  }
}
