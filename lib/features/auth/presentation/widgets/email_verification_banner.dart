import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';
import '../providers/auth_providers.dart';

class EmailVerificationBanner extends ConsumerStatefulWidget {
  const EmailVerificationBanner({super.key});

  @override
  ConsumerState<EmailVerificationBanner> createState() =>
      _EmailVerificationBannerState();
}

class _EmailVerificationBannerState
    extends ConsumerState<EmailVerificationBanner>
    with WidgetsBindingObserver {
  bool _isSending = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadUser();
    }
  }

  Future<void> _reloadUser() async {
    try {
      await ref.read(authRepositoryProvider).reloadCurrentUser();
      if (mounted) setState(() => _statusMessage = null);
    } on AuthException catch (error) {
      if (mounted) setState(() => _statusMessage = error.message);
    }
  }

  Future<void> _sendVerification(User user) async {
    setState(() {
      _isSending = true;
      _statusMessage = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendEmailVerification(user);
      if (mounted) {
        setState(() => _statusMessage = 'Verification email sent. Check your inbox.');
      }
    } on AuthException catch (error) {
      if (mounted) setState(() => _statusMessage = error.message);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ref.watch(userChangesProvider).when(
          data: (user) {
            if (user == null || user.email == null || user.emailVerified) {
              return const SizedBox.shrink();
            }
            return _buildBanner(
              context,
              user,
              _statusMessage ??
                  'Please verify your email address to secure your account.',
              'Resend email',
              () => _sendVerification(user),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (error, _) => _buildBanner(
            context,
            null,
            'Could not check email verification status: $error',
            'Retry',
            () => _reloadUser(),
          ),
        );
  }

  Widget _buildBanner(
    BuildContext context,
    User? user,
    String message,
    String actionLabel,
    VoidCallback onPressed,
  ) {
    return MaterialBanner(
      content: Text(message),
      leading: const Icon(Icons.mark_email_unread_outlined),
      actions: [
        TextButton(
          onPressed: _isSending
              ? null
              : user == null
                  ? onPressed
                  : () => _sendVerification(user),
          child: Text(_isSending ? 'Sending…' : actionLabel),
        ),
      ],
    );
  }
}
