import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/inventory_screen.dart';

void main() {
  runApp(const FridgeMateApp());
}

class FridgeMateApp extends StatelessWidget {
  const FridgeMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Fridge Mate',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 236, 155, 5),
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.rubikTextTheme(),
      ),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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
        backgroundColor: const Color.fromARGB(255, 254, 215, 97),
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
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 254, 215, 97),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Menu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
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
              leading: const Icon(Icons.info_outline),
              title: const Text('O aplikaci'),
              onTap: () {},
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
          color: Colors.white,
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
          selectedItemColor: Colors.black,
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
                      color: _tabIndex == 0 ? Colors.black : Colors.grey,
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
                    child: const Icon(Icons.home, size: 26, color: Colors.black),
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
                      color: _tabIndex == 1 ? Colors.black : Colors.grey,
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
                    child: const Icon(
                      Icons.inventory_2,
                      size: 26,
                      color: Colors.black,
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
}