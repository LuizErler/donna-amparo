import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/care_team_providers.dart';

/// Aceita convite pendente (?invite=...) antes do fluxo normal do app.
class PendingInviteGate extends ConsumerWidget {
  const PendingInviteGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(pendingInviteTokenProvider);
    if (token == null) return child;

    final acceptAsync = ref.watch(acceptPendingInviteProvider);

    return acceptAsync.when(
      loading: () => const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Aceitando convite...'),
            ],
          ),
        ),
      ),
      error: (error, _) => _InviteErrorScreen(
        message: error.toString().replaceFirst('Exception: ', ''),
        onContinue: () {
          ref.read(pendingInviteTokenProvider.notifier).state = null;
          ref.invalidate(acceptPendingInviteProvider);
        },
      ),
      data: (_) => child,
    );
  }
}

class _InviteErrorScreen extends StatelessWidget {
  const _InviteErrorScreen({
    required this.message,
    required this.onContinue,
  });

  final String message;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Icon(Icons.link_off, size: 48, color: Colors.red.shade700),
              const SizedBox(height: 16),
              Text('Convite indisponivel',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(message, style: Theme.of(context).textTheme.bodyLarge),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: onContinue,
                  child: const Text('Continuar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
