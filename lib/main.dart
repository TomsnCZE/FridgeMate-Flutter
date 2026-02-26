import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'models/product.dart';
import 'screens/about_screen.dart';
import 'screens/home_screen.dart';
import 'screens/inventory_screen.dart';
import 'screens/settings_screen.dart';
import 'services/database_service.dart';
import 'services/settings_service.dart';
import 'themes/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Android only: keep the top status bar, hide only the bottom system navigation bar.
  if (Platform.isAndroid) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top],
    );
  }
  await EasyLocalization.ensureInitialized();

  off.OpenFoodAPIConfiguration.userAgent = off.UserAgent(name: 'Fridge Mate');
  off.OpenFoodAPIConfiguration.globalLanguages = [
    off.OpenFoodFactsLanguage.CZECH,
  ];

  final savedLocaleCode = await SettingsService.getLocaleCode();
  final startLocale = savedLocaleCode == null ? null : Locale(savedLocaleCode);

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('cs'), Locale('en'), Locale('de'), Locale('fr'), Locale('es'), Locale('it')],
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
    setState(() => _isDarkMode = value);
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
      home: AppShell(
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

class AppShell extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  final String currentSeedKey;
  final ValueChanged<String> onSeedChanged;

  const AppShell({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
    required this.currentSeedKey,
    required this.onSeedChanged,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _tabIndex = 0;
  int _expiredBadgeCount = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadExpiredBadgeCount();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadExpiredBadgeCount();
    }
  }

  Future<void> _loadExpiredBadgeCount() async {
    try {
      final data = await DatabaseService.instance.getAllProducts();
      final products = data.map((e) => Product.fromMap(e)).toList();

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final expired = products.where((p) {
        final d = p.expirationDate;
        if (d == null) return false;
        final dd = DateTime(d.year, d.month, d.day);
        return dd.isBefore(today);
      }).length;

      if (!mounted) return;
      setState(() => _expiredBadgeCount = expired);
    } catch (_) {
      
    }
  }

  Widget _badgeIfNeeded({required Widget child}) {
    if (_expiredBadgeCount <= 0) return child;

    final text = _expiredBadgeCount > 99 ? '99+' : _expiredBadgeCount.toString();

    return Badge(
      label: Text(text),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const HomeScreen(),
      InventoryScreen(
        onInventoryChanged: _loadExpiredBadgeCount,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
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
          onDestinationSelected: (index) {
            setState(() => _tabIndex = index);
            _loadExpiredBadgeCount();
          },
          indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.home_outlined, size: 22),
              selectedIcon: const Icon(Icons.home, size: 22),
              label: 'nav.home'.tr(),
            ),
            NavigationDestination(
              icon: _badgeIfNeeded(
                child: const Icon(Icons.inventory_2_outlined, size: 22),
              ),
              selectedIcon: _badgeIfNeeded(
                child: const Icon(Icons.inventory_2, size: 22),
              ),
              label: 'nav.inventory'.tr(),
            ),
          ],
        ),
      ),
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