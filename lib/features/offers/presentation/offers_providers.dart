import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/offers/data/offers_repository.dart';

part 'offers_providers.g.dart';

@riverpod
OffersRepository offersRepository(Ref ref) =>
    OffersRepository(ref.watch(apiClientProvider));

@riverpod
Future<MyOffers> myOffers(Ref ref) => ref.watch(offersRepositoryProvider).mine();
