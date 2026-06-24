import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/home/home_page.dart';
import 'features/medicamentos/medicamentos_page.dart';
import 'features/consultas/consultas_page.dart';
import 'features/familia/familia_page.dart';
import 'features/alertas/alertas_page.dart';

// Notifier global para controlar o tema — acessivel em qualquer tela
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

// Credenciais injetadas em tempo de compilacao pelo GitHub Actions (--dart-define)
const _compiledUrl = String.fromEnvironment('SUPABASE_URL');
const _compiledKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Em producao (build web) usa --dart-define; em dev local usa .env
  String supabaseUrl;
  String supabaseKey;

  if (_compiledUrl.isNotEmpty && _compiledKey.isNotEmpty) {
    supabaseUrl = _compiledUrl;
    supabaseKey = _compiledKey;
  } else {
    await dotenv.load(fileName: '.env', isOptional: true);
    supabaseUrl = dotenv.env['SUPABASE_URL'] ?? '';
    supabaseKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

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
