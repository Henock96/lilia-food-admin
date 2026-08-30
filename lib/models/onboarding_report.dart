/// Checklist « prêt à vendre » d'un vendeur, **calculée par le backend**.
///
/// ⚠️ Ne jamais recalculer `isReady` côté Flutter. Deux implémentations de la
/// même règle finissent toujours par diverger, et c'est le serveur qui décide
/// d'accepter ou de refuser l'activation : une interface qui prétendrait le
/// contraire proposerait un bouton menant à un 409.
class OnboardingReport {
  final String restaurantId;

  /// `DRAFT` | `READY` | `ACTIVATED`.
  final String onboardingStatus;

  /// Toutes les cases bloquantes sont cochées.
  final bool isReady;

  /// Avancement sur les seules cases bloquantes (0–100).
  final int progress;

  final List<ReadinessCheck> checks;
  final List<String> blockingIssues;

  const OnboardingReport({
    required this.restaurantId,
    required this.onboardingStatus,
    required this.isReady,
    required this.progress,
    this.checks = const [],
    this.blockingIssues = const [],
  });

  factory OnboardingReport.fromJson(Map<String, dynamic> json) {
    return OnboardingReport(
      restaurantId: json['restaurantId'] as String? ?? '',
      onboardingStatus: json['onboardingStatus'] as String? ?? 'DRAFT',
      isReady: json['isReady'] as bool? ?? false,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      checks: (json['checks'] as List?)
              ?.map((c) => ReadinessCheck.fromJson(c as Map<String, dynamic>))
              .toList() ??
          const [],
      blockingIssues:
          (json['blockingIssues'] as List?)?.cast<String>() ?? const [],
    );
  }

  bool get isActivated => onboardingStatus == 'ACTIVATED';

  ReadinessCheck? checkFor(String key) {
    for (final c in checks) {
      if (c.key == key) return c;
    }
    return null;
  }
}

/// Une case de la checklist.
class ReadinessCheck {
  /// Identifiant stable : `owner`, `identity`, `logo`, `gps`, `hours`… Sert à
  /// relier la case à l'étape correspondante du wizard.
  final String key;
  final String label;

  /// `OK` | `MISSING` | `INVALID`.
  final String status;

  /// Une case non bloquante manquante n'empêche pas l'activation.
  final bool blocking;
  final String? detail;

  const ReadinessCheck({
    required this.key,
    required this.label,
    required this.status,
    required this.blocking,
    this.detail,
  });

  factory ReadinessCheck.fromJson(Map<String, dynamic> json) {
    return ReadinessCheck(
      key: json['key'] as String? ?? '',
      label: json['label'] as String? ?? '',
      status: json['status'] as String? ?? 'MISSING',
      blocking: json['blocking'] as bool? ?? false,
      detail: json['detail'] as String?,
    );
  }

  bool get isOk => status == 'OK';
}

/// Résultat de l'invitation d'activation envoyée au propriétaire.
///
/// `activationLink` n'est renseigné **que** si l'e-mail n'est pas parti : c'est
/// le repli qui permet à l'administrateur de débloquer le vendeur à la main
/// plutôt que de le laisser sans accès à son compte.
class VendorInvitationResult {
  final bool emailSent;
  final bool smsSent;
  final String? activationLink;
  final String detail;

  const VendorInvitationResult({
    required this.emailSent,
    required this.smsSent,
    this.activationLink,
    required this.detail,
  });

  factory VendorInvitationResult.fromJson(Map<String, dynamic> json) {
    return VendorInvitationResult(
      emailSent: json['emailSent'] as bool? ?? false,
      smsSent: json['smsSent'] as bool? ?? false,
      activationLink: json['activationLink'] as String?,
      detail: json['detail'] as String? ?? '',
    );
  }
}
