// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_tracking_socket_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adminTrackingSocketService)
final adminTrackingSocketServiceProvider =
    AdminTrackingSocketServiceProvider._();

final class AdminTrackingSocketServiceProvider
    extends
        $FunctionalProvider<
          AdminTrackingSocketService,
          AdminTrackingSocketService,
          AdminTrackingSocketService
        >
    with $Provider<AdminTrackingSocketService> {
  AdminTrackingSocketServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adminTrackingSocketServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adminTrackingSocketServiceHash();

  @$internal
  @override
  $ProviderElement<AdminTrackingSocketService> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AdminTrackingSocketService create(Ref ref) {
    return adminTrackingSocketService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AdminTrackingSocketService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AdminTrackingSocketService>(value),
    );
  }
}

String _$adminTrackingSocketServiceHash() =>
    r'f2228277afc19e20362a80e8b2dc35c08814a3e7';
