import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'pending_mfa_sign_in.g.dart';

/// F3-08 — connexion interrompue par le second facteur (TOTP). Tant qu'il
/// est non nul, l'écran de connexion demande le code de l'application
/// d'authentification.
@Riverpod(keepAlive: true)
class PendingMfaSignIn extends _$PendingMfaSignIn {
  @override
  MultiFactorResolver? build() => null;

  void wait(MultiFactorResolver resolver) => state = resolver;

  void clear() => state = null;
}

/// Le facteur TOTP parmi ceux proposés ; `null` si le compte n'en a pas.
MultiFactorInfo? totpHint(List<MultiFactorInfo> hints) {
  for (final hint in hints) {
    if (hint.factorId == 'totp') return hint;
  }
  return null;
}

/// Code d'application d'authentification : 6 chiffres.
bool isTotpCode(String value) => RegExp(r'^\d{6}$').hasMatch(value);
