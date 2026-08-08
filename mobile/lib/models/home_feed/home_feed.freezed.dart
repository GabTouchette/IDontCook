// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_feed.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

HomeFeedContext _$HomeFeedContextFromJson(Map<String, dynamic> json) {
  return _HomeFeedContext.fromJson(json);
}

/// @nodoc
mixin _$HomeFeedContext {
  String get daypart => throw _privateConstructorUsedError;
  bool get is_weekend => throw _privateConstructorUsedError;
  String? get mood => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HomeFeedContextCopyWith<HomeFeedContext> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HomeFeedContextCopyWith<$Res> {
  factory $HomeFeedContextCopyWith(
          HomeFeedContext value, $Res Function(HomeFeedContext) then) =
      _$HomeFeedContextCopyWithImpl<$Res, HomeFeedContext>;
  @useResult
  $Res call({String daypart, bool is_weekend, String? mood});
}

/// @nodoc
class _$HomeFeedContextCopyWithImpl<$Res, $Val extends HomeFeedContext>
    implements $HomeFeedContextCopyWith<$Res> {
  _$HomeFeedContextCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? daypart = null,
    Object? is_weekend = null,
    Object? mood = freezed,
  }) {
    return _then(_value.copyWith(
      daypart: null == daypart
          ? _value.daypart
          : daypart // ignore: cast_nullable_to_non_nullable
              as String,
      is_weekend: null == is_weekend
          ? _value.is_weekend
          : is_weekend // ignore: cast_nullable_to_non_nullable
              as bool,
      mood: freezed == mood
          ? _value.mood
          : mood // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HomeFeedContextImplCopyWith<$Res>
    implements $HomeFeedContextCopyWith<$Res> {
  factory _$$HomeFeedContextImplCopyWith(_$HomeFeedContextImpl value,
          $Res Function(_$HomeFeedContextImpl) then) =
      __$$HomeFeedContextImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String daypart, bool is_weekend, String? mood});
}

/// @nodoc
class __$$HomeFeedContextImplCopyWithImpl<$Res>
    extends _$HomeFeedContextCopyWithImpl<$Res, _$HomeFeedContextImpl>
    implements _$$HomeFeedContextImplCopyWith<$Res> {
  __$$HomeFeedContextImplCopyWithImpl(
      _$HomeFeedContextImpl _value, $Res Function(_$HomeFeedContextImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? daypart = null,
    Object? is_weekend = null,
    Object? mood = freezed,
  }) {
    return _then(_$HomeFeedContextImpl(
      daypart: null == daypart
          ? _value.daypart
          : daypart // ignore: cast_nullable_to_non_nullable
              as String,
      is_weekend: null == is_weekend
          ? _value.is_weekend
          : is_weekend // ignore: cast_nullable_to_non_nullable
              as bool,
      mood: freezed == mood
          ? _value.mood
          : mood // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HomeFeedContextImpl extends _HomeFeedContext {
  const _$HomeFeedContextImpl(
      {this.daypart = '', this.is_weekend = false, this.mood})
      : super._();

  factory _$HomeFeedContextImpl.fromJson(Map<String, dynamic> json) =>
      _$$HomeFeedContextImplFromJson(json);

  @override
  @JsonKey()
  final String daypart;
  @override
  @JsonKey()
  final bool is_weekend;
  @override
  final String? mood;

  @override
  String toString() {
    return 'HomeFeedContext(daypart: $daypart, is_weekend: $is_weekend, mood: $mood)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HomeFeedContextImpl &&
            (identical(other.daypart, daypart) || other.daypart == daypart) &&
            (identical(other.is_weekend, is_weekend) ||
                other.is_weekend == is_weekend) &&
            (identical(other.mood, mood) || other.mood == mood));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, daypart, is_weekend, mood);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HomeFeedContextImplCopyWith<_$HomeFeedContextImpl> get copyWith =>
      __$$HomeFeedContextImplCopyWithImpl<_$HomeFeedContextImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HomeFeedContextImplToJson(
      this,
    );
  }
}

abstract class _HomeFeedContext extends HomeFeedContext {
  const factory _HomeFeedContext(
      {final String daypart,
      final bool is_weekend,
      final String? mood}) = _$HomeFeedContextImpl;
  const _HomeFeedContext._() : super._();

  factory _HomeFeedContext.fromJson(Map<String, dynamic> json) =
      _$HomeFeedContextImpl.fromJson;

  @override
  String get daypart;
  @override
  bool get is_weekend;
  @override
  String? get mood;
  @override
  @JsonKey(ignore: true)
  _$$HomeFeedContextImplCopyWith<_$HomeFeedContextImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HomeFeed _$HomeFeedFromJson(Map<String, dynamic> json) {
  return _HomeFeed.fromJson(json);
}

/// @nodoc
mixin _$HomeFeed {
  String get feed_id => throw _privateConstructorUsedError;
  HomeFeedContext get context => throw _privateConstructorUsedError;
  String get greeting => throw _privateConstructorUsedError;
  List<Block> get blocks => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HomeFeedCopyWith<HomeFeed> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HomeFeedCopyWith<$Res> {
  factory $HomeFeedCopyWith(HomeFeed value, $Res Function(HomeFeed) then) =
      _$HomeFeedCopyWithImpl<$Res, HomeFeed>;
  @useResult
  $Res call(
      {String feed_id,
      HomeFeedContext context,
      String greeting,
      List<Block> blocks});

  $HomeFeedContextCopyWith<$Res> get context;
}

/// @nodoc
class _$HomeFeedCopyWithImpl<$Res, $Val extends HomeFeed>
    implements $HomeFeedCopyWith<$Res> {
  _$HomeFeedCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? feed_id = null,
    Object? context = null,
    Object? greeting = null,
    Object? blocks = null,
  }) {
    return _then(_value.copyWith(
      feed_id: null == feed_id
          ? _value.feed_id
          : feed_id // ignore: cast_nullable_to_non_nullable
              as String,
      context: null == context
          ? _value.context
          : context // ignore: cast_nullable_to_non_nullable
              as HomeFeedContext,
      greeting: null == greeting
          ? _value.greeting
          : greeting // ignore: cast_nullable_to_non_nullable
              as String,
      blocks: null == blocks
          ? _value.blocks
          : blocks // ignore: cast_nullable_to_non_nullable
              as List<Block>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $HomeFeedContextCopyWith<$Res> get context {
    return $HomeFeedContextCopyWith<$Res>(_value.context, (value) {
      return _then(_value.copyWith(context: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$HomeFeedImplCopyWith<$Res>
    implements $HomeFeedCopyWith<$Res> {
  factory _$$HomeFeedImplCopyWith(
          _$HomeFeedImpl value, $Res Function(_$HomeFeedImpl) then) =
      __$$HomeFeedImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String feed_id,
      HomeFeedContext context,
      String greeting,
      List<Block> blocks});

  @override
  $HomeFeedContextCopyWith<$Res> get context;
}

/// @nodoc
class __$$HomeFeedImplCopyWithImpl<$Res>
    extends _$HomeFeedCopyWithImpl<$Res, _$HomeFeedImpl>
    implements _$$HomeFeedImplCopyWith<$Res> {
  __$$HomeFeedImplCopyWithImpl(
      _$HomeFeedImpl _value, $Res Function(_$HomeFeedImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? feed_id = null,
    Object? context = null,
    Object? greeting = null,
    Object? blocks = null,
  }) {
    return _then(_$HomeFeedImpl(
      feed_id: null == feed_id
          ? _value.feed_id
          : feed_id // ignore: cast_nullable_to_non_nullable
              as String,
      context: null == context
          ? _value.context
          : context // ignore: cast_nullable_to_non_nullable
              as HomeFeedContext,
      greeting: null == greeting
          ? _value.greeting
          : greeting // ignore: cast_nullable_to_non_nullable
              as String,
      blocks: null == blocks
          ? _value._blocks
          : blocks // ignore: cast_nullable_to_non_nullable
              as List<Block>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HomeFeedImpl extends _HomeFeed {
  const _$HomeFeedImpl(
      {this.feed_id = '',
      this.context = const HomeFeedContext(),
      this.greeting = '',
      final List<Block> blocks = const <Block>[]})
      : _blocks = blocks,
        super._();

  factory _$HomeFeedImpl.fromJson(Map<String, dynamic> json) =>
      _$$HomeFeedImplFromJson(json);

  @override
  @JsonKey()
  final String feed_id;
  @override
  @JsonKey()
  final HomeFeedContext context;
  @override
  @JsonKey()
  final String greeting;
  final List<Block> _blocks;
  @override
  @JsonKey()
  List<Block> get blocks {
    if (_blocks is EqualUnmodifiableListView) return _blocks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_blocks);
  }

  @override
  String toString() {
    return 'HomeFeed(feed_id: $feed_id, context: $context, greeting: $greeting, blocks: $blocks)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HomeFeedImpl &&
            (identical(other.feed_id, feed_id) || other.feed_id == feed_id) &&
            (identical(other.context, context) || other.context == context) &&
            (identical(other.greeting, greeting) ||
                other.greeting == greeting) &&
            const DeepCollectionEquality().equals(other._blocks, _blocks));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, feed_id, context, greeting,
      const DeepCollectionEquality().hash(_blocks));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HomeFeedImplCopyWith<_$HomeFeedImpl> get copyWith =>
      __$$HomeFeedImplCopyWithImpl<_$HomeFeedImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HomeFeedImplToJson(
      this,
    );
  }
}

abstract class _HomeFeed extends HomeFeed {
  const factory _HomeFeed(
      {final String feed_id,
      final HomeFeedContext context,
      final String greeting,
      final List<Block> blocks}) = _$HomeFeedImpl;
  const _HomeFeed._() : super._();

  factory _HomeFeed.fromJson(Map<String, dynamic> json) =
      _$HomeFeedImpl.fromJson;

  @override
  String get feed_id;
  @override
  HomeFeedContext get context;
  @override
  String get greeting;
  @override
  List<Block> get blocks;
  @override
  @JsonKey(ignore: true)
  _$$HomeFeedImplCopyWith<_$HomeFeedImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
