import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Annonce au serveur quelle application et quelle version parlent.
///
/// ## Pourquoi (audit du 28/10/2026)
///
/// Seule l'app client envoyait sa version. L'app vendeurs n'en disait rien :
/// le serveur ne pouvait ni refuser un binaire trop ancien ni lui répondre
/// `426` pour réclamer une mise à jour. Toute évolution des statuts de commande
/// devait donc rester compatible avec un parc qu'on ne pouvait pas faire
/// évoluer — c'est le préalable du parcours « accepter avant de payer ».
///
/// `X-Lilia-App: vendor` distingue ce binaire de l'app client : leurs versions
/// sont numérotées séparément, et le seuil `minAppVersion` de l'app client ne
/// doit jamais s'appliquer à celle-ci.
///
/// ## Jamais bloquant
///
/// Version illisible : en-tête de version omis, la requête part quand même. Le
/// serveur traite un signal absent comme absent.
class AppVersionInterceptor extends Interceptor {
  AppVersionInterceptor({Future<String?> Function()? readVersion})
      : _readVersion = readVersion ?? _fromPackageInfo;

  static const appHeader = 'X-Lilia-App';
  static const versionHeader = 'X-Lilia-App-Version';
  static const appName = 'vendor';

  /// Lot 3 — cette version sait afficher une demande (`DEMANDE_ENVOYEE`) et
  /// y répondre (accepter / refuser avant paiement). Le serveur ne bascule le
  /// parcours « accepter puis payer » que pour les applications qui
  /// l'annoncent ; les autres reçoivent un `426` quand il est allumé.
  static const orderFlowHeader = 'X-Lilia-Order-Flow';
  static const orderFlowCapability = 'accept-first';

  final Future<String?> Function() _readVersion;
  String? _cached;

  static Future<String?> _fromPackageInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (info.version.isEmpty) return null;
      return info.buildNumber.isEmpty
          ? info.version
          : '${info.version}+${info.buildNumber}';
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers[appHeader] = appName;
    options.headers[orderFlowHeader] = orderFlowCapability;
    final version = _cached ??= await _readVersion();
    if (version != null) {
      options.headers[versionHeader] = version;
    }
    handler.next(options);
  }
}
