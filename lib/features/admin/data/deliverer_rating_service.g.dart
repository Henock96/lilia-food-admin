// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'deliverer_rating_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `GET /delivery-reviews/deliverer/:id/stats` — route publique côté backend
/// (c'est une information d'affichage, sans identité de client ni détail de
/// course).

@ProviderFor(delivererRating)
final delivererRatingProvider = DelivererRatingFamily._();

/// `GET /delivery-reviews/deliverer/:id/stats` — route publique côté backend
/// (c'est une information d'affichage, sans identité de client ni détail de
/// course).

final class DelivererRatingProvider
    extends
        $FunctionalProvider<
          AsyncValue<DelivererRating>,
          DelivererRating,
          FutureOr<DelivererRating>
        >
    with $FutureModifier<DelivererRating>, $FutureProvider<DelivererRating> {
  /// `GET /delivery-reviews/deliverer/:id/stats` — route publique côté backend
  /// (c'est une information d'affichage, sans identité de client ni détail de
  /// course).
  DelivererRatingProvider._({
    required DelivererRatingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'delivererRatingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$delivererRatingHash();

  @override
  String toString() {
    return r'delivererRatingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<DelivererRating> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<DelivererRating> create(Ref ref) {
    final argument = this.argument as String;
    return delivererRating(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DelivererRatingProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$delivererRatingHash() => r'7bfa20003360aecf68a402c544a126b51923d5c8';

/// `GET /delivery-reviews/deliverer/:id/stats` — route publique côté backend
/// (c'est une information d'affichage, sans identité de client ni détail de
/// course).

final class DelivererRatingFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<DelivererRating>, String> {
  DelivererRatingFamily._()
    : super(
        retry: null,
        name: r'delivererRatingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// `GET /delivery-reviews/deliverer/:id/stats` — route publique côté backend
  /// (c'est une information d'affichage, sans identité de client ni détail de
  /// course).

  DelivererRatingProvider call(String delivererId) =>
      DelivererRatingProvider._(argument: delivererId, from: this);

  @override
  String toString() => r'delivererRatingProvider';
}
