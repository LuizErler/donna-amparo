import 'app_exception.dart';

/// Executa uma acao assincrona e retorna mensagem de erro ou null em sucesso.
Future<String?> runGuarded(
  Future<void> Function() action, {
  String fallback = 'Ocorreu um erro inesperado. Tente novamente.',
}) async {
  try {
    await action();
    return null;
  } on AppException catch (e) {
    return e.message;
  } catch (_) {
    return fallback;
  }
}
