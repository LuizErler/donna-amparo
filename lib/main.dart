import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/home/home_page.dart';
import 'features/medicamentos/medicamentos_page.dart';
import 'features/consultas/consultas_page.dart';
import 'features/familia/familia_page.dart';
import 'features/alertas/alertas_page.dart';

// Notifier global para controlar o tema — acessivel em qualquer tela
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) => MaterialApp(
        title: 'Donna Amparo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: mode,
        home: const LoginPage(),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    HomePage(),
    MedicamentosPage(),
    ConsultasPage(),
    FamiliaPage(),
    AlertasPage(),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(label: 'Inicio',       icon: Icons.home_outlined,          activeIcon: Icons.home),
    _NavItem(label: 'Medicamentos', icon: Icons.medication_outlined,     activeIcon: Icons.medication),
    _NavItem(label: 'Consultas',    icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today),
    _NavItem(label: 'Familia',      icon: Icons.people_outline,          activeIcon: Icons.people),
    _NavItem(label: 'Alertas',      icon: Icons.notifications_outlined,  activeIcon: Icons.notifications),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        items: _navItems
            .map((item) => BottomNavigationBarItem(
                  icon: Icon(item.icon),
                  activeIcon: Icon(item.activeIcon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavItem(
      {required this.label, required this.icon, required this.activeIcon});
}
