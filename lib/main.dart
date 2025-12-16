import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/inventory_screen.dart';
import 'screens/settings_screen.dart';
import 'package:openfoodfacts/openfoodfacts.dart' as off;
import 'screens/about_screen.dart';
import 'screens/nutriscore_test.dart';
import 'themes/app_theme.dart';

void main() {
  off.OpenFoodAPIConfiguration.userAgent = off.UserAgent(name: 'Fridge Mate');

  off.OpenFoodAPIConfiguration.globalLanguages = [
    off.OpenFoodFactsLanguage.CZECH,
  ];
  runApp(const FridgeMateApp());
}

class FridgeMateApp extends StatefulWidget {
  const FridgeMateApp({super.key});

  @override
  State<FridgeMateApp> createState() => _FridgeMateAppState();
}

class _FridgeMateAppState extends State<FridgeMateApp> {
  bool _isDarkMode = false;

  @override
  void initState() {
    super.initState();
    _loadThemeSetting();
  }

  Future<void> _loadThemeSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('dark_mode') ?? false;
    });
  }

  void _toggleDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fridge Mate',

      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,

      home: HomeScreen(
        isDarkMode: _isDarkMode,
        onThemeChanged: _toggleDarkMode,
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;

  const HomeScreen({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
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
          _tabIndex == 0 ? 'Domů' : 'Sklad',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          ),
        ),
      ),

      drawerEnableOpenDragGesture: true,
      drawer: Drawer(
        elevation: 16,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: widget.isDarkMode ? Colors.black : Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Domů'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _tabIndex = 0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Sklad'),
              onTap: () {
                Navigator.pop(context);
                setState(() => _tabIndex = 1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bakery_dining),
              title: const Text('Test Nutriscore'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NutriscoreTestScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Nastavení'),
              onTap: () {
                Navigator.pop(context);
                _openSettingsScreen(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('O aplikaci'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),
          ],
        ),
      ),

      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: pages[_tabIndex],
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          elevation: 0,
          currentIndex: _tabIndex,
          onTap: (index) => setState(() => _tabIndex = index),
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: [
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                padding: const EdgeInsets.all(6),
                child: Transform.translate(
                  offset: Offset(0, _tabIndex == 0 ? -4 : 0),
                  child: AnimatedScale(
                    scale: _tabIndex == 0 ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      Icons.home_outlined,
                      size: 26,
                      color: _tabIndex == 0
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              activeIcon: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                padding: const EdgeInsets.all(6),
                child: Transform.translate(
                  offset: Offset(0, _tabIndex == 0 ? -4 : 0),
                  child: AnimatedScale(
                    scale: _tabIndex == 0 ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      Icons.home,
                      size: 26,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              label: 'Domů',
            ),
            BottomNavigationBarItem(
              icon: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                padding: const EdgeInsets.all(6),
                child: Transform.translate(
                  offset: Offset(0, _tabIndex == 1 ? -4 : 0),
                  child: AnimatedScale(
                    scale: _tabIndex == 1 ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      Icons.inventory_2_outlined,
                      size: 26,
                      color: _tabIndex == 1
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
              activeIcon: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                padding: const EdgeInsets.all(6),
                child: Transform.translate(
                  offset: Offset(0, _tabIndex == 1 ? -4 : 0),
                  child: AnimatedScale(
                    scale: _tabIndex == 1 ? 1.2 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutBack,
                    child: Icon(
                      Icons.inventory_2,
                      size: 26,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              label: 'Sklad',
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
                "Celkem produktů",
                _totalProducts,
                Icons.inventory_2,
                isDarkMode,
              ),
              _buildStatCard(
                "Brzy expiruje",
                _expiringSoonCount,
                Icons.warning,
                isDarkMode,
              ),
              _buildStatCard("Prošlé", _expiredCount, Icons.error, isDarkMode),
              _buildStatCard(
                "Spotřebováno",
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
                    'Pozor na expirace!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[800],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_expiringSoonCount produktů brzy expiruje',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() => _tabIndex = 1);
              },
              child: const Text('Zobrazit'),
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
          'Rychlé akce',
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
              child: _buildActionButton('Přidat ručně', Icons.add, () {
                // Otevře přidání produktu
              }, isDarkMode),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Skenovat QR',
                Icons.qr_code_scanner,
                () {
                  // Otevře QR scanner
                },
                isDarkMode,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton('Rychlý výběr', Icons.category, () {
                // Otevře rychlý výběr
              }, isDarkMode),
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
          'Rychlý přístup',
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
              'Nákupní seznam',
              Icons.shopping_cart,
              isDarkMode,
            ),
            _buildQuickAccessCard('Statistiky', Icons.bar_chart, isDarkMode),
            _buildQuickAccessCard('Recepty', Icons.restaurant_menu, isDarkMode),
            _buildQuickAccessCard('Nastavení', Icons.settings, isDarkMode),
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
          'Nedávná aktivita',
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
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Zatím placeholder - později reálná data
                Text(
                  'Zatím žádná aktivita',
                  style: TextStyle(color: Colors.grey),
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
          'Doporučení',
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
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                // Zatím placeholder - později chytré tipy
                Text(
                  'Přidej více produktů pro personalizovaná doporučení',
                  style: TextStyle(color: Colors.grey),
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
        ),
      ),
    );
  }
}
