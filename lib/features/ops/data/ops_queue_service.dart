import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/utils/api_response.dart';

/// Cockpit ops « À traiter » (F3-04) — files **calculées** par le serveur.
class OpsItem {
  final String id;
  final String? orderId;
  final String title;
  final String? detail;
  final DateTime since;

  const OpsItem({
    required this.id,
    this.orderId,
    required this.title,
    this.detail,
    required this.since,
  });

  factory OpsItem.fromJson(Map<String, dynamic> json) => OpsItem(
    id: json['id'] as String,
    orderId: json['orderId'] as String?,
    title: json['title'] as String? ?? '',
    detail: json['detail'] as String?,
    since: DateTime.parse(json['since'] as String),
  );
}

class OpsBucket {
  final String key;
  final String label;

  /// `HIGH` ou `MEDIUM`.
  final String severity;
  final int count;
  final List<OpsItem> items;

  const OpsBucket({
    required this.key,
    required this.label,
    required this.severity,
    required this.count,
    this.items = const [],
  });

  bool get isHigh => severity == 'HIGH';

  factory OpsBucket.fromJson(Map<String, dynamic> json) => OpsBucket(
    key: json['key'] as String,
    label: json['label'] as String? ?? json['key'] as String,
    severity: json['severity'] as String? ?? 'MEDIUM',
    count: (json['count'] as num?)?.toInt() ?? 0,
    items: ((json['items'] as List?) ?? const [])
        .map((i) => OpsItem.fromJson(i as Map<String, dynamic>))
        .toList(),
  );
}

class OpsQueue {
  final int total;
  final List<OpsBucket> buckets;

  const OpsQueue({required this.total, required this.buckets});

  /// Files non vides, dans l'ordre du serveur.
  List<OpsBucket> get active => buckets.where((b) => b.count > 0).toList();

  factory OpsQueue.fromJson(Map<String, dynamic> json) => OpsQueue(
    total: (json['total'] as num?)?.toInt() ?? 0,
    buckets: ((json['buckets'] as List?) ?? const [])
        .map((b) => OpsBucket.fromJson(b as Map<String, dynamic>))
        .toList(),
  );
}

/// « il y a 12 min », « il y a 3 h », « il y a 2 j ».
String ageLabel(DateTime since, {DateTime? now}) {
  final minutes = (now ?? DateTime.now()).difference(since).inMinutes;
  if (minutes < 60) return 'il y a ${minutes < 0 ? 0 : minutes} min';
  final hours = minutes ~/ 60;
  if (hours < 48) return 'il y a $hours h';
  return 'il y a ${hours ~/ 24} j';
}

class OpsQueueService {
  final ApiClient _api;
  OpsQueueService(this._api);

  Future<OpsQueue> fetch() async {
    final res = await _api.getJson('/admin/ops/queue');
    return OpsQueue.fromJson(ApiResponse.mapOf(res.data));
  }
}

final opsQueueServiceProvider = Provider(
  (ref) => OpsQueueService(ref.watch(apiClientProvider)),
);

final opsQueueProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(opsQueueServiceProvider).fetch(),
);
