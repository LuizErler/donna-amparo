import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Invalida e aguarda o reload de um [FutureProvider].
Future<void> refreshFutureProvider<T>(
  WidgetRef ref,
  FutureProvider<T> provider,
) async {
  ref.invalidate(provider);
  await ref.read(provider.future);
}

/// Invalida e aguarda varios [FutureProvider]s em sequencia.
Future<void> refreshFutureProviders(
  WidgetRef ref,
  List<FutureProvider<dynamic>> providers,
) async {
  for (final provider in providers) {
    ref.invalidate(provider);
  }
  for (final provider in providers) {
    await ref.read(provider.future);
  }
}
