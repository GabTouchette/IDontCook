// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RecipeSummary _$RecipeSummaryFromJson(Map<String, dynamic> json) {
  return _RecipeSummary.fromJson(json);
}

/// @nodoc
mixin _$RecipeSummary {
  int get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get image_url => throw _privateConstructorUsedError;
  int? get total_time => throw _privateConstructorUsedError;
  int? get calories => throw _privateConstructorUsedError;
  List<String> get tags =>
      throw _privateConstructorUsedError; // Whether this recipe belongs to the current user (their own saved/created
// recipe) vs. a catalog find. Optional/defaulted for forward-compat with
// older payloads that don't send it.
  bool get is_owned => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RecipeSummaryCopyWith<RecipeSummary> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecipeSummaryCopyWith<$Res> {
  factory $RecipeSummaryCopyWith(
          RecipeSummary value, $Res Function(RecipeSummary) then) =
      _$RecipeSummaryCopyWithImpl<$Res, RecipeSummary>;
  @useResult
  $Res call(
      {int id,
      String title,
      String? image_url,
      int? total_time,
      int? calories,
      List<String> tags,
      bool is_owned});
}

/// @nodoc
class _$RecipeSummaryCopyWithImpl<$Res, $Val extends RecipeSummary>
    implements $RecipeSummaryCopyWith<$Res> {
  _$RecipeSummaryCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? image_url = freezed,
    Object? total_time = freezed,
    Object? calories = freezed,
    Object? tags = null,
    Object? is_owned = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      image_url: freezed == image_url
          ? _value.image_url
          : image_url // ignore: cast_nullable_to_non_nullable
              as String?,
      total_time: freezed == total_time
          ? _value.total_time
          : total_time // ignore: cast_nullable_to_non_nullable
              as int?,
      calories: freezed == calories
          ? _value.calories
          : calories // ignore: cast_nullable_to_non_nullable
              as int?,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      is_owned: null == is_owned
          ? _value.is_owned
          : is_owned // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecipeSummaryImplCopyWith<$Res>
    implements $RecipeSummaryCopyWith<$Res> {
  factory _$$RecipeSummaryImplCopyWith(
          _$RecipeSummaryImpl value, $Res Function(_$RecipeSummaryImpl) then) =
      __$$RecipeSummaryImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String title,
      String? image_url,
      int? total_time,
      int? calories,
      List<String> tags,
      bool is_owned});
}

/// @nodoc
class __$$RecipeSummaryImplCopyWithImpl<$Res>
    extends _$RecipeSummaryCopyWithImpl<$Res, _$RecipeSummaryImpl>
    implements _$$RecipeSummaryImplCopyWith<$Res> {
  __$$RecipeSummaryImplCopyWithImpl(
      _$RecipeSummaryImpl _value, $Res Function(_$RecipeSummaryImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? image_url = freezed,
    Object? total_time = freezed,
    Object? calories = freezed,
    Object? tags = null,
    Object? is_owned = null,
  }) {
    return _then(_$RecipeSummaryImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      image_url: freezed == image_url
          ? _value.image_url
          : image_url // ignore: cast_nullable_to_non_nullable
              as String?,
      total_time: freezed == total_time
          ? _value.total_time
          : total_time // ignore: cast_nullable_to_non_nullable
              as int?,
      calories: freezed == calories
          ? _value.calories
          : calories // ignore: cast_nullable_to_non_nullable
              as int?,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      is_owned: null == is_owned
          ? _value.is_owned
          : is_owned // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecipeSummaryImpl implements _RecipeSummary {
  const _$RecipeSummaryImpl(
      {required this.id,
      required this.title,
      this.image_url,
      this.total_time,
      this.calories,
      final List<String> tags = const <String>[],
      this.is_owned = false})
      : _tags = tags;

  factory _$RecipeSummaryImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipeSummaryImplFromJson(json);

  @override
  final int id;
  @override
  final String title;
  @override
  final String? image_url;
  @override
  final int? total_time;
  @override
  final int? calories;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

// Whether this recipe belongs to the current user (their own saved/created
// recipe) vs. a catalog find. Optional/defaulted for forward-compat with
// older payloads that don't send it.
  @override
  @JsonKey()
  final bool is_owned;

  @override
  String toString() {
    return 'RecipeSummary(id: $id, title: $title, image_url: $image_url, total_time: $total_time, calories: $calories, tags: $tags, is_owned: $is_owned)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipeSummaryImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.image_url, image_url) ||
                other.image_url == image_url) &&
            (identical(other.total_time, total_time) ||
                other.total_time == total_time) &&
            (identical(other.calories, calories) ||
                other.calories == calories) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.is_owned, is_owned) ||
                other.is_owned == is_owned));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, image_url, total_time,
      calories, const DeepCollectionEquality().hash(_tags), is_owned);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipeSummaryImplCopyWith<_$RecipeSummaryImpl> get copyWith =>
      __$$RecipeSummaryImplCopyWithImpl<_$RecipeSummaryImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecipeSummaryImplToJson(
      this,
    );
  }
}

abstract class _RecipeSummary implements RecipeSummary {
  const factory _RecipeSummary(
      {required final int id,
      required final String title,
      final String? image_url,
      final int? total_time,
      final int? calories,
      final List<String> tags,
      final bool is_owned}) = _$RecipeSummaryImpl;

  factory _RecipeSummary.fromJson(Map<String, dynamic> json) =
      _$RecipeSummaryImpl.fromJson;

  @override
  int get id;
  @override
  String get title;
  @override
  String? get image_url;
  @override
  int? get total_time;
  @override
  int? get calories;
  @override
  List<String> get tags;
  @override // Whether this recipe belongs to the current user (their own saved/created
// recipe) vs. a catalog find. Optional/defaulted for forward-compat with
// older payloads that don't send it.
  bool get is_owned;
  @override
  @JsonKey(ignore: true)
  _$$RecipeSummaryImplCopyWith<_$RecipeSummaryImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
