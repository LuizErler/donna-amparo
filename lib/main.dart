import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/config/app_config.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseKey = String.fromEnvironment('SUPABASE_ANON_KEY');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);

  if (AppConfig.enableAuth) {
    if (supabaseUrl.isEmpty || supabaseKey.isEmpty) {
      throw Exception(
        'Credenciais Supabase nao configuradas.\n'
        'Crie dart_defines.local.json (copie de dart_defines.local.json.example) '
        'ou rode: flutter run --dart-define-from-file=dart_defines.local.json\n'
        'No Cursor/VS Code: use F5 com "Donna Amparo (Android)".',
      );
    }
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseKey,
    );
  }

  runApp(
    const ProviderScope(
      child: DonnaAmparoApp(),
    ),
  );
}
