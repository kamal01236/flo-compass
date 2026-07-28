import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';

class AuthCallbackScreen extends StatefulWidget {
  const AuthCallbackScreen({
    super.key,
    required this.code,
    required this.state,
    required this.error,
  });

  final String? code;
  final String? state;
  final String? error;

  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _handle());
  }

  Future<void> _handle() async {
    final auth = context.read<AuthState>();
    final ok = await auth.handleCallback(
      code: widget.code,
      state: widget.state,
      error: widget.error,
    );
    if (!mounted) return;
    final returnUrl = auth.consumeReturnUrl() ?? '/profile';
    if (!ok) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.authSignInFailed)));
    }
    context.go(returnUrl);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              l10n.authCompletingSignIn,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
