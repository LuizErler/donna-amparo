import 'package:flutter/foundation.dart';

/// URL de retorno para e-mail de recuperacao de senha (Supabase Auth).
String get authRedirectUrl {
  if (kIsWeb) {
    final base = Uri.base;
    final path = base.path.endsWith('/') ? base.path : '${base.path}/';
    return '${base.origin}$path';
  }
  return 'io.supabase.donnaamparo://login-callback/';
}
