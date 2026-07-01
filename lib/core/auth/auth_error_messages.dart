/// Traduz mensagens comuns do Supabase Auth para portugues.
String mapAuthError(String message) {
  final lower = message.toLowerCase();

  if (lower.contains('invalid login credentials')) {
    return 'E-mail ou senha incorretos.';
  }
  if (lower.contains('email not confirmed')) {
    return 'Confirme seu e-mail antes de entrar.';
  }
  if (lower.contains('user already registered')) {
    return 'Este e-mail ja possui cadastro.';
  }
  if (lower.contains('password should be at least')) {
    return 'A senha deve ter no minimo 6 caracteres.';
  }
  if (lower.contains('unable to validate email address')) {
    return 'E-mail invalido.';
  }
  if (lower.contains('rate limit') || lower.contains('email rate limit')) {
    return 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
  }
  if (lower.contains('for security purposes')) {
    return 'Por seguranca, aguarde alguns segundos antes de tentar novamente.';
  }
  if (lower.contains('same password')) {
    return 'A nova senha deve ser diferente da atual.';
  }

  return message;
}
