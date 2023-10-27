// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'courrier_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

Courrier _$CourrierFromJson(Map<String, dynamic> json) {
  return _Courrier.fromJson(json);
}

/// @nodoc
mixin _$Courrier {
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get id => throw _privateConstructorUsedError;
  String get sender => throw _privateConstructorUsedError;
  String get object => throw _privateConstructorUsedError;
  List<Map<String, String>> get annotations =>
      throw _privateConstructorUsedError;
  String? get url => throw _privateConstructorUsedError;
  @TimestampSerializer()
  DateTime get date => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CourrierCopyWith<Courrier> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CourrierCopyWith<$Res> {
  factory $CourrierCopyWith(Courrier value, $Res Function(Courrier) then) =
      _$CourrierCopyWithImpl<$Res, Courrier>;
  @useResult
  $Res call(
      {@JsonKey(includeFromJson: false, includeToJson: false) String? id,
      String sender,
      String object,
      List<Map<String, String>> annotations,
      String? url,
      @TimestampSerializer() DateTime date});
}

/// @nodoc
class _$CourrierCopyWithImpl<$Res, $Val extends Courrier>
    implements $CourrierCopyWith<$Res> {
  _$CourrierCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? sender = null,
    Object? object = null,
    Object? annotations = null,
    Object? url = freezed,
    Object? date = null,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      sender: null == sender
          ? _value.sender
          : sender // ignore: cast_nullable_to_non_nullable
              as String,
      object: null == object
          ? _value.object
          : object // ignore: cast_nullable_to_non_nullable
              as String,
      annotations: null == annotations
          ? _value.annotations
          : annotations // ignore: cast_nullable_to_non_nullable
              as List<Map<String, String>>,
      url: freezed == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CourrierImplCopyWith<$Res>
    implements $CourrierCopyWith<$Res> {
  factory _$$CourrierImplCopyWith(
          _$CourrierImpl value, $Res Function(_$CourrierImpl) then) =
      __$$CourrierImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {@JsonKey(includeFromJson: false, includeToJson: false) String? id,
      String sender,
      String object,
      List<Map<String, String>> annotations,
      String? url,
      @TimestampSerializer() DateTime date});
}

/// @nodoc
class __$$CourrierImplCopyWithImpl<$Res>
    extends _$CourrierCopyWithImpl<$Res, _$CourrierImpl>
    implements _$$CourrierImplCopyWith<$Res> {
  __$$CourrierImplCopyWithImpl(
      _$CourrierImpl _value, $Res Function(_$CourrierImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? sender = null,
    Object? object = null,
    Object? annotations = null,
    Object? url = freezed,
    Object? date = null,
  }) {
    return _then(_$CourrierImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String?,
      sender: null == sender
          ? _value.sender
          : sender // ignore: cast_nullable_to_non_nullable
              as String,
      object: null == object
          ? _value.object
          : object // ignore: cast_nullable_to_non_nullable
              as String,
      annotations: null == annotations
          ? _value._annotations
          : annotations // ignore: cast_nullable_to_non_nullable
              as List<Map<String, String>>,
      url: freezed == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String?,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CourrierImpl implements _Courrier {
  const _$CourrierImpl(
      {@JsonKey(includeFromJson: false, includeToJson: false) this.id,
      required this.sender,
      required this.object,
      required final List<Map<String, String>> annotations,
      this.url,
      @TimestampSerializer() required this.date})
      : _annotations = annotations;

  factory _$CourrierImpl.fromJson(Map<String, dynamic> json) =>
      _$$CourrierImplFromJson(json);

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  final String? id;
  @override
  final String sender;
  @override
  final String object;
  final List<Map<String, String>> _annotations;
  @override
  List<Map<String, String>> get annotations {
    if (_annotations is EqualUnmodifiableListView) return _annotations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_annotations);
  }

  @override
  final String? url;
  @override
  @TimestampSerializer()
  final DateTime date;

  @override
  String toString() {
    return 'Courrier(id: $id, sender: $sender, object: $object, annotations: $annotations, url: $url, date: $date)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CourrierImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sender, sender) || other.sender == sender) &&
            (identical(other.object, object) || other.object == object) &&
            const DeepCollectionEquality()
                .equals(other._annotations, _annotations) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.date, date) || other.date == date));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, sender, object,
      const DeepCollectionEquality().hash(_annotations), url, date);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CourrierImplCopyWith<_$CourrierImpl> get copyWith =>
      __$$CourrierImplCopyWithImpl<_$CourrierImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CourrierImplToJson(
      this,
    );
  }
}

abstract class _Courrier implements Courrier {
  const factory _Courrier(
      {@JsonKey(includeFromJson: false, includeToJson: false) final String? id,
      required final String sender,
      required final String object,
      required final List<Map<String, String>> annotations,
      final String? url,
      @TimestampSerializer() required final DateTime date}) = _$CourrierImpl;

  factory _Courrier.fromJson(Map<String, dynamic> json) =
      _$CourrierImpl.fromJson;

  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  String? get id;
  @override
  String get sender;
  @override
  String get object;
  @override
  List<Map<String, String>> get annotations;
  @override
  String? get url;
  @override
  @TimestampSerializer()
  DateTime get date;
  @override
  @JsonKey(ignore: true)
  _$$CourrierImplCopyWith<_$CourrierImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
