// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'async_task_details.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$asyncTaskDetailsHash() => r'0bfcedf0bb60e998fd26b192bc95604bec2d5edf';

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

abstract class _$AsyncTaskDetails
    extends BuildlessAutoDisposeAsyncNotifier<Task> {
  late final String id;

  FutureOr<Task> build(
    String id,
  );
}

/// See also [AsyncTaskDetails].
@ProviderFor(AsyncTaskDetails)
const asyncTaskDetailsProvider = AsyncTaskDetailsFamily();

/// See also [AsyncTaskDetails].
class AsyncTaskDetailsFamily extends Family<AsyncValue<Task>> {
  /// See also [AsyncTaskDetails].
  const AsyncTaskDetailsFamily();

  /// See also [AsyncTaskDetails].
  AsyncTaskDetailsProvider call(
    String id,
  ) {
    return AsyncTaskDetailsProvider(
      id,
    );
  }

  @override
  AsyncTaskDetailsProvider getProviderOverride(
    covariant AsyncTaskDetailsProvider provider,
  ) {
    return call(
      provider.id,
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
  String? get name => r'asyncTaskDetailsProvider';
}

/// See also [AsyncTaskDetails].
class AsyncTaskDetailsProvider
    extends AutoDisposeAsyncNotifierProviderImpl<AsyncTaskDetails, Task> {
  /// See also [AsyncTaskDetails].
  AsyncTaskDetailsProvider(
    String id,
  ) : this._internal(
          () => AsyncTaskDetails()..id = id,
          from: asyncTaskDetailsProvider,
          name: r'asyncTaskDetailsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$asyncTaskDetailsHash,
          dependencies: AsyncTaskDetailsFamily._dependencies,
          allTransitiveDependencies:
              AsyncTaskDetailsFamily._allTransitiveDependencies,
          id: id,
        );

  AsyncTaskDetailsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  FutureOr<Task> runNotifierBuild(
    covariant AsyncTaskDetails notifier,
  ) {
    return notifier.build(
      id,
    );
  }

  @override
  Override overrideWith(AsyncTaskDetails Function() create) {
    return ProviderOverride(
      origin: this,
      override: AsyncTaskDetailsProvider._internal(
        () => create()..id = id,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<AsyncTaskDetails, Task>
      createElement() {
    return _AsyncTaskDetailsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AsyncTaskDetailsProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin AsyncTaskDetailsRef on AutoDisposeAsyncNotifierProviderRef<Task> {
  /// The parameter `id` of this provider.
  String get id;
}

class _AsyncTaskDetailsProviderElement
    extends AutoDisposeAsyncNotifierProviderElement<AsyncTaskDetails, Task>
    with AsyncTaskDetailsRef {
  _AsyncTaskDetailsProviderElement(super.provider);

  @override
  String get id => (origin as AsyncTaskDetailsProvider).id;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
