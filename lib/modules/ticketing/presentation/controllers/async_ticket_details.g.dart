// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'async_ticket_details.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncTicketDetailsHash() =>
    r'951fc3a55a17fb1cba5f691ef8500781568492f4';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$AsyncTicketDetails
    extends BuildlessAutoDisposeAsyncNotifier<Ticket> {
  late final String ticketId;

  FutureOr<Ticket> build(
    String ticketId,
  );
}

/// See also [AsyncTicketDetails].
@ProviderFor(AsyncTicketDetails)
const asyncTicketDetailsProvider = AsyncTicketDetailsFamily();

/// See also [AsyncTicketDetails].
class AsyncTicketDetailsFamily extends Family<AsyncValue<Ticket>> {
  /// See also [AsyncTicketDetails].
  const AsyncTicketDetailsFamily();

  /// See also [AsyncTicketDetails].
  AsyncTicketDetailsProvider call(
    String ticketId,
  ) {
    return AsyncTicketDetailsProvider(
      ticketId,
    );
  }

  @override
  AsyncTicketDetailsProvider getProviderOverride(
    covariant AsyncTicketDetailsProvider provider,
  ) {
    return call(
      provider.ticketId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'asyncTicketDetailsProvider';
}

/// See also [AsyncTicketDetails].
class AsyncTicketDetailsProvider
    extends AutoDisposeAsyncNotifierProviderImpl<AsyncTicketDetails, Ticket> {
  /// See also [AsyncTicketDetails].
  AsyncTicketDetailsProvider(
    String ticketId,
  ) : this._internal(
          () => AsyncTicketDetails()..ticketId = ticketId,
          from: asyncTicketDetailsProvider,
          name: r'asyncTicketDetailsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$asyncTicketDetailsHash,
          dependencies: AsyncTicketDetailsFamily._dependencies,
          allTransitiveDependencies:
              AsyncTicketDetailsFamily._allTransitiveDependencies,
          ticketId: ticketId,
        );

  AsyncTicketDetailsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.ticketId,
  }) : super.internal();

  final String ticketId;

  @override
  FutureOr<Ticket> runNotifierBuild(
    covariant AsyncTicketDetails notifier,
  ) {
    return notifier.build(
      ticketId,
    );
  }

  @override
  Override overrideWith(AsyncTicketDetails Function() create) {
    return ProviderOverride(
      origin: this,
      override: AsyncTicketDetailsProvider._internal(
        () => create()..ticketId = ticketId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        ticketId: ticketId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<AsyncTicketDetails, Ticket>
      createElement() {
    return _AsyncTicketDetailsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AsyncTicketDetailsProvider && other.ticketId == ticketId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, ticketId.hashCode);

    return _SystemHash.finish(hash);
  }
}

// Riverpod 2 generates this deprecated reference type for compatibility.
// ignore: deprecated_member_use
mixin AsyncTicketDetailsRef on AutoDisposeAsyncNotifierProviderRef<Ticket> {
  /// The parameter `ticketId` of this provider.
  String get ticketId;
}

class _AsyncTicketDetailsProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AsyncTicketDetails, Ticket>
    with AsyncTicketDetailsRef {
  _AsyncTicketDetailsProviderElement(super.provider);

  @override
  String get ticketId => (origin as AsyncTicketDetailsProvider).ticketId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
