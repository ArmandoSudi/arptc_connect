// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncServiceHash() => r'32886cc6352517d186c83d36bf0ded07e99eaeed';

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

abstract class _$AsyncService
    extends BuildlessAutoDisposeAsyncNotifier<List<Service>> {
  late final String directionRef;

  FutureOr<List<Service>> build(
    String directionRef,
  );
}

/// See also [AsyncService].
@ProviderFor(AsyncService)
const asyncServiceProvider = AsyncServiceFamily();

/// See also [AsyncService].
class AsyncServiceFamily extends Family<AsyncValue<List<Service>>> {
  /// See also [AsyncService].
  const AsyncServiceFamily();

  /// See also [AsyncService].
  AsyncServiceProvider call(
    String directionRef,
  ) {
    return AsyncServiceProvider(
      directionRef,
    );
  }

  @override
  AsyncServiceProvider getProviderOverride(
    covariant AsyncServiceProvider provider,
  ) {
    return call(
      provider.directionRef,
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
  String? get name => r'asyncServiceProvider';
}

/// See also [AsyncService].
class AsyncServiceProvider
    extends AutoDisposeAsyncNotifierProviderImpl<AsyncService, List<Service>> {
  /// See also [AsyncService].
  AsyncServiceProvider(
    String directionRef,
  ) : this._internal(
          () => AsyncService()..directionRef = directionRef,
          from: asyncServiceProvider,
          name: r'asyncServiceProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$asyncServiceHash,
          dependencies: AsyncServiceFamily._dependencies,
          allTransitiveDependencies:
              AsyncServiceFamily._allTransitiveDependencies,
          directionRef: directionRef,
        );

  AsyncServiceProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.directionRef,
  }) : super.internal();

  final String directionRef;

  @override
  FutureOr<List<Service>> runNotifierBuild(
    covariant AsyncService notifier,
  ) {
    return notifier.build(
      directionRef,
    );
  }

  @override
  Override overrideWith(AsyncService Function() create) {
    return ProviderOverride(
      origin: this,
      override: AsyncServiceProvider._internal(
        () => create()..directionRef = directionRef,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        directionRef: directionRef,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<AsyncService, List<Service>>
      createElement() {
    return _AsyncServiceProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AsyncServiceProvider && other.directionRef == directionRef;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, directionRef.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AsyncServiceRef on AutoDisposeAsyncNotifierProviderRef<List<Service>> {
  /// The parameter `directionRef` of this provider.
  String get directionRef;
}

class _AsyncServiceProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AsyncService, List<Service>>
    with AsyncServiceRef {
  _AsyncServiceProviderElement(super.provider);

  @override
  String get directionRef => (origin as AsyncServiceProvider).directionRef;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
