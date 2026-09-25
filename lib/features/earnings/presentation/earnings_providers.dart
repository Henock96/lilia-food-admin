import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/earnings/data/earnings_repository.dart';

part 'earnings_providers.g.dart';

@riverpod
EarningsRepository earningsRepository(Ref ref) =>
    EarningsRepository(ref.watch(apiClientProvider));

@riverpod
Future<VendorEarnings> vendorEarnings(Ref ref) =>
    ref.watch(earningsRepositoryProvider).mine();
