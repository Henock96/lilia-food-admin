// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reviews_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(reviewsRepository)
final reviewsRepositoryProvider = ReviewsRepositoryProvider._();

final class ReviewsRepositoryProvider
    extends
        $FunctionalProvider<
          ReviewsRepository,
          ReviewsRepository,
          ReviewsRepository
        >
    with $Provider<ReviewsRepository> {
  ReviewsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'reviewsRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$reviewsRepositoryHash();

  @$internal
  @override
  $ProviderElement<ReviewsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ReviewsRepository create(Ref ref) {
    return reviewsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReviewsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReviewsRepository>(value),
    );
  }
}

String _$reviewsRepositoryHash() => r'fa2433f785d90be346ab45786a472a6755d578a9';

@ProviderFor(receivedReviews)
final receivedReviewsProvider = ReceivedReviewsProvider._();

final class ReceivedReviewsProvider
    extends
        $FunctionalProvider<
          AsyncValue<ReceivedReviews>,
          ReceivedReviews,
          FutureOr<ReceivedReviews>
        >
    with $FutureModifier<ReceivedReviews>, $FutureProvider<ReceivedReviews> {
  ReceivedReviewsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'receivedReviewsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$receivedReviewsHash();

  @$internal
  @override
  $FutureProviderElement<ReceivedReviews> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<ReceivedReviews> create(Ref ref) {
    return receivedReviews(ref);
  }
}

String _$receivedReviewsHash() => r'170934fca9f9b69aef6e5aea32e4123bdff5e370';
