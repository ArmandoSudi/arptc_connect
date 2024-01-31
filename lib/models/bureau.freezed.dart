// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bureau.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

Bureau _$BureauFromJson(Map<String, dynamic> json) {
  return _Bureau.fromJson(json);
}

/// @nodoc
mixin _$Bureau {
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  @JsonKey(name: "service_ref")
  String get directionRef => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BureauCopyWith<Bureau> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BureauCopyWith<$Res> {
  factory $BureauCopyWith(Bureau value, $Res Function(Bureau) then) =
      _$BureauCopyWithImpl<$Res, Bureau>;
  @useResult
  $Res call(
      {@JsonKey(includeFromJson: false, includeToJson: false) String? id,
      String name,
      @JsonKey(name: "service_ref") String directionRef});
}

/// @nodoc
class _$BureauCopyWithImpl<$Res, $Val extends Bureau>
    implements $BureauCopyWith<$Res> {
  _$BureauCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = null,
    Object? directionRef = null,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      directionRef: null == directionRef
          ? _value.directionRef
          : directionRef // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BureauImplCopyWith<$Res> implements $BureauCopyWith<$Res> {
  factory _$$BureauImplCopyWith(
          _$BureauImpl value, $Res Function(_$BureauImpl) then) =
      __$$BureauImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(includeFromJson: false, includeToJson: false) String? id,
      String name,
      @JsonKey(name: "service_ref") String directionRef});
}

/// @nodoc
class __$$BureauImplCopyWithImpl<$Res>
    extends _$BureauCopyWithImpl<$Res, _$BureauImpl>
    implements _$$BureauImplCopyWith<$Res> {
  __$$BureauImplCopyWithImpl(
      _$BureauImpl _value, $Res Function(_$BureauImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = null,
    Object? directionRef = null,
  }) {
    return _then(_$BureauImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      directionRef: null == directionRef
          ? _value.directionRef
          : directionRef // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BureauImpl extends _Bureau {
  const _$BureauImpl(
      {@JsonKey(includeFromJson: false, includeToJson: false) this.id,
      required this.name,
      @JsonKey(name: "service_ref") required this.directionRef})
      : super._();

  factory _$BureauImpl.fromJson(Map<String, dynamic> json) =>
      _$$BureauImplFromJson(json);

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? id;
  @override
  final String name;
  @override
  @JsonKey(name: "service_ref")
  final String directionRef;

  @override
  String toString() {
    return 'Bureau(id: $id, name: $name, directionRef: $directionRef)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BureauImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.directionRef, directionRef) ||
                other.directionRef == directionRef));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, directionRef);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BureauImplCopyWith<_$BureauImpl> get copyWith =>
      __$$BureauImplCopyWithImpl<_$BureauImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BureauImplToJson(
      this,
    );
  }
}

abstract class _Bureau extends Bureau {
  const factory _Bureau(
      {@JsonKey(includeFromJson: false, includeToJson: false) final String? id,
      required final String name,
      @JsonKey(name: "service_ref")
      required final String directionRef}) = _$BureauImpl;
  const _Bureau._() : super._();

  factory _Bureau.fromJson(Map<String, dynamic> json) = _$BureauImpl.fromJson;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get id;
  @override
  String get name;
  @override
  @JsonKey(name: "service_ref")
  String get directionRef;
  @override
  @JsonKey(ignore: true)
  _$$BureauImplCopyWith<_$BureauImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
