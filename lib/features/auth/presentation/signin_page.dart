import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lilia_admin/constants/app_size.dart';

import '../controller/auth_controller.dart';
import '../controller/pending_mfa_sign_in.dart';

class SignInPage extends ConsumerWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // F3-08 — second facteur : demander le code de l'application.
    ref.listen(pendingMfaSignInProvider, (prev, resolver) async {
      if (resolver == null || prev != null) return;
      final code = await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const TotpCodeDialog(),
      );
      if (code == null) {
        ref.read(pendingMfaSignInProvider.notifier).clear();
        return;
      }
      await ref.read(authControllerProvider.notifier).completeMfaSignIn(code);
    });
    ref.listen(authControllerProvider, (prev, state) {
      if (state.hasError && !state.isLoading) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${state.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: Sizes.p24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [const _Header(), gapH32, const _SignInForm()],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        gapH64,
        Icon(Icons.fastfood, size: 80, color: theme.colorScheme.primary),
        gapH16,
        Text(
          'Bienvenue sur Lilia Food',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        gapH8,
        Text(
          'Connectez-vous à votre compte',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _SignInForm extends ConsumerStatefulWidget {
  const _SignInForm();

  @override
  ConsumerState<_SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends ConsumerState<_SignInForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (_formKey.currentState!.validate()) {
      await ref
          .read(authControllerProvider.notifier)
          .sigInInUserWithEmailAndPassword(
            _emailController.text.trim(),
            _passwordController.text.trim(),
          );
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _sendResetEmail() async {
    final emailController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser le mot de passe'),
        content: TextField(
          controller: emailController,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Entrez votre email'),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              if (emailController.text.isNotEmpty) {
                Navigator.of(context).pop(emailController.text);
              }
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await ref
            .read(authControllerProvider.notifier)
            .sendPasswordResetEmailWithEmail(result);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Un e-mail de réinitialisation a été envoyé.'),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              errorStyle: TextStyle(
                color: Theme.of(context).textTheme.titleLarge!.color,
              ),
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre email';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Veuillez entrer un email valide';
              }
              return null;
            },
          ),
          gapH20,
          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'Mot de Passe',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
                onPressed: _togglePasswordVisibility,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre mot de passe';
              }
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _sendResetEmail,
              child: const Text('Mot de passe oublié ?'),
            ),
          ),
          gapH16,
          ElevatedButton(
            onPressed: state.isLoading ? null : _signIn,
            child: state.isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white),
                  )
                : const Text('Se connecter'),
          ),
        ],
      ),
    );
  }
}

/// F3-08 — code à 6 chiffres de l'application d'authentification.
class TotpCodeDialog extends StatefulWidget {
  const TotpCodeDialog({super.key});

  @override
  State<TotpCodeDialog> createState() => _TotpCodeDialogState();
}

class _TotpCodeDialogState extends State<TotpCodeDialog> {
  final _code = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Double authentification'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Saisissez le code à 6 chiffres affiché par votre application '
            'd’authentification.',
          ),
          const SizedBox(height: 12),
          TextField(
            key: const Key('totp-code'),
            controller: _code,
            autofocus: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, letterSpacing: 8),
            decoration: const InputDecoration(counterText: '', hintText: '000000'),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(
          key: const Key('totp-submit'),
          onPressed: isTotpCode(_code.text)
              ? () => Navigator.pop(context, _code.text)
              : null,
          child: const Text('Valider'),
        ),
      ],
    );
  }
}
