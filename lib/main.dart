import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/inventory_screen.dart';
import 'screens/settings_screen.dart';

void main() {
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
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomeScreen(
        isDarkMode: _isDarkMode,
        onThemeChanged: _toggleDarkMode,
      ),
    );
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color.fromARGB(255, 236, 155, 5),
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Color.fromARGB(255, 254, 215, 97),
        foregroundColor: Colors.black,
      ),
      textTheme: GoogleFonts.rubikTextTheme(ThemeData.light().textTheme),
    );
  }

ThemeData _buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color.fromARGB(255, 236, 155, 5),
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: const Color(0xFF121212),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color.fromARGB(255, 254, 215, 97),
      foregroundColor: Colors.black,
    ),
    textTheme: GoogleFonts.rubikTextTheme(ThemeData.dark().textTheme),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const Center(
        child: Text(
          'Domů',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ),
      const InventoryScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tabIndex == 0 ? 'Domů' : 'Sklad',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Color(0xFFEC9B05),
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
              decoration: const BoxDecoration(
                color: Color(0xFFEC9B05),
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
                // Otevře About screen - doděláme později
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
          color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
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
          selectedItemColor: widget.isDarkMode ? Colors.white : Colors.black,
          unselectedItemColor: Colors.grey,
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
                          ? (widget.isDarkMode ? Colors.white : Colors.black)
                          : Colors.grey,
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
                      color: widget.isDarkMode ? Colors.white : Colors.black
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
                          ? (widget.isDarkMode ? Colors.white : Colors.black)
                          : Colors.grey,
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
                      color: widget.isDarkMode ? Colors.white : Colors.black,
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