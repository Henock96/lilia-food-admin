// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(auditLogService)
final auditLogServiceProvider = AuditLogServiceProvider._();

final class AuditLogServiceProvider
    extends
        $FunctionalProvider<AuditLogService, AuditLogService, AuditLogService>
    with $Provider<AuditLogService> {
  AuditLogServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'auditLogServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$auditLogServiceHash();

  @$internal
  @override
  $ProviderElement<AuditLogService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AuditLogService create(Ref ref) {
    return auditLogService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuditLogService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuditLogService>(value),
    );
  }
}

String _$auditLogServiceHash() => r'7feb88ab364b9f6127f5c423f7576081d724b094';

@ProviderFor(auditLogList)
final auditLogListProvider = AuditLogListFamily._();

final class AuditLogListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AuditLogEntry>>,
          List<AuditLogEntry>,
          FutureOr<List<AuditLogEntry>>
        >
    with
        $FutureModifier<List<AuditLogEntry>>,
        $FutureProvider<List<AuditLogEntry>> {
  AuditLogListProvider._({
    required AuditLogListFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'auditLogListProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$auditLogListHash();

  @override
  String toString() {
    return r'auditLogListProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<AuditLogEntry>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AuditLogEntry>> create(Ref ref) {
    final argument = this.argument as String?;
    return auditLogList(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AuditLogListProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$auditLogListHash() => r'90c3d7cf1138e2935cea3992ae23765cbea945c8';

final class AuditLogListFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<AuditLogEntry>>, String?> {
  AuditLogListFamily._()
    : super(
        retry: null,
        name: r'auditLogListProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  AuditLogListProvider call(String? action) =>
      AuditLogListProvider._(argument: action, from: this);

  @override
  String toString() => r'auditLogListProvider';
}
