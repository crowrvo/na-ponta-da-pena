import 'package:flutter/material.dart';

import 'auth_session.dart';

class AuthenticationGate extends StatefulWidget {
  const AuthenticationGate({
    super.key,
    required this.session,
    required this.authenticatedBuilder,
  });

  final AuthenticationSession session;
  final Widget Function(BuildContext context, VoidCallback logout)
  authenticatedBuilder;

  @override
  State<AuthenticationGate> createState() => _AuthenticationGateState();
}

class _AuthenticationGateState extends State<AuthenticationGate> {
  @override
  void initState() {
    super.initState();
    widget.session.initialize();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.session,
    builder: (context, _) => switch (widget.session.status) {
      AuthSessionStatus.loading => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      AuthSessionStatus.authenticated => widget.authenticatedBuilder(
        context,
        () => widget.session.logout(),
      ),
      AuthSessionStatus.unauthenticated ||
      AuthSessionStatus.failure => Scaffold(
        appBar: AppBar(title: const Text('VMS Finance')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 56),
                  const SizedBox(height: 16),
                  Text(
                    'Entre para acessar sua família',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  if (widget.session.errorMessage case final error?) ...[
                    const SizedBox(height: 12),
                    Text(error, textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: widget.session.login,
                    icon: const Icon(Icons.login),
                    label: const Text('Entrar com Auth0'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    },
  );
}
