import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_message_mapper.dart';

/// Renderiza estados padrao de [AsyncValue]: loading, erro e data.
class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.value,
    required this.data,
    this.loading,
    this.errorBuilder,
    this.errorFallback = 'Nao foi possivel carregar os dados.',
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final Widget Function(Object error, StackTrace stackTrace)? errorBuilder;
  final String errorFallback;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => loading ?? const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) =>
          errorBuilder?.call(error, stackTrace) ??
          _DefaultAsyncError(
            message: mapErrorMessage(error, fallback: errorFallback),
          ),
      data: data,
    );
  }
}

class _DefaultAsyncError extends StatelessWidget {
  const _DefaultAsyncError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
