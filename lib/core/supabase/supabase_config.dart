import 'package:supabase_flutter/supabase_flutter.dart';

/// Atalho global para acessar o cliente Supabase em qualquer lugar do app.
SupabaseClient get supabase => Supabase.instance.client;
