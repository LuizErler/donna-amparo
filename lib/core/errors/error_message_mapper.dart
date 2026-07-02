import 'app_exception.dart';

/// Converte erros de dominio/dados em mensagem amigavel para a UI.
String mapErrorMessage(
  Object error, {
  String fallback = 'Ocorreu um erro inesperado. Tente novamente.',
}) {
  if (error is AppException) return error.message;

  final text = error.toString();
  if (text.startsWith('Exception: ')) {
    return text.substring('Exception: '.length);
  }
  if (text.isNotEmpty && text != 'null') return text;

  return fallback;
}
