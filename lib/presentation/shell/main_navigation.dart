import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/push/push_navigation.dart';
import '../features/alertas/alertas_page.dart';
import '../features/calendario/calendario_page.dart';
import '../features/consultas/consultas_page.dart';
import '../features/home/home_page.dart';
import '../features/medicamentos/medicamentos_page.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = [
    HomePage(),
    MedicamentosPage(),
    ConsultasPage(),
    CalendarioPage(),
    AlertasPage(),
  ];

  static const List<_NavItem> _navItems = [
    _NavItem(label: 'Início', icon: Icons.home_outlined, activeIcon: Icons.home),
    _NavItem(
        label: 'Medicamentos',
        icon: Icons.medication_outlined,
        activeIcon: Icons.medication),
    _NavItem(
        label: 'Consultas',
        icon: Icons.medical_services_outlined,
        activeIcon: Icons.medical_services),
    _NavItem(
        label: 'Calendário',
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month),
    _NavItem(
        label: 'Alertas',
        icon: Icons.notifications_outlined,
        activeIcon: Icons.notifications),
  ];

  @override
  Widget build(BuildContext context) {
    ref.listen<PushNavigationTarget?>(pushNavigationTargetProvider, (_, next) {
      if (next == null) return;
      setState(() => _selectedIndex = next.tabIndex);
      ref.read(pushNavigationTargetProvider.notifier).state = null;
    });

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
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
