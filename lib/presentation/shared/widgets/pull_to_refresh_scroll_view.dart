import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// [RefreshIndicator] + [SingleChildScrollView] com scroll sempre habilitado.
class PullToRefreshScrollView extends ConsumerWidget {
  const PullToRefreshScrollView({
    super.key,
    required this.onRefresh,
    required this.child,
    this.padding,
  });

  final Future<void> Function(WidgetRef ref) onRefresh;
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => onRefresh(ref),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        child: child,
      ),
    );
  }
}

/// [RefreshIndicator] + [ListView] com scroll sempre habilitado.
class PullToRefreshListView extends ConsumerWidget {
  const PullToRefreshListView({
    super.key,
    required this.onRefresh,
    required this.children,
    this.padding,
  });

  final Future<void> Function(WidgetRef ref) onRefresh;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () => onRefresh(ref),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: children,
      ),
    );
  }
}
