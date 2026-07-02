import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_message_mapper.dart';
import 'error_state_view.dart';
import 'loading_state_view.dart';

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
      loading: () => loading ?? const LoadingStateView(),
      error: (error, stackTrace) =>
          errorBuilder?.call(error, stackTrace) ??
          ErrorStateView(
            message: mapErrorMessage(error, fallback: errorFallback),
          ),
      data: data,
    );
  }
}
