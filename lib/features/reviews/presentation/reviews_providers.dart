import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:lilia_admin/core/network/api_client.dart';
import 'package:lilia_admin/features/reviews/data/reviews_repository.dart';

part 'reviews_providers.g.dart';

@riverpod
ReviewsRepository reviewsRepository(Ref ref) =>
    ReviewsRepository(ref.watch(apiClientProvider));

@riverpod
Future<ReceivedReviews> receivedReviews(Ref ref) =>
    ref.watch(reviewsRepositoryProvider).received();
