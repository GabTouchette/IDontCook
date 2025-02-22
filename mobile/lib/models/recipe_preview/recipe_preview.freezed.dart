// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe_preview.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RecipePreview _$RecipePreviewFromJson(Map<String, dynamic> json) {
  return _RecipePreview.fromJson(json);
}

/// @nodoc
mixin _$RecipePreview {
  int get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  int? get preparation_time => throw _privateConstructorUsedError;
  int? get cooking_time => throw _privateConstructorUsedError;
  String? get thumbnail_url => throw _privateConstructorUsedError;
  List<String>? get tags => throw _privateConstructorUsedError;
  bool? get is_favorite => throw _privateConstructorUsedError;
  DateTime? get last_visited_at => throw _privateConstructorUsedError;

  /// Serializes this RecipePreview to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecipePreview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecipePreviewCopyWith<RecipePreview> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecipePreviewCopyWith<$Res> {
  factory $RecipePreviewCopyWith(
          RecipePreview value, $Res Function(RecipePreview) then) =
      _$RecipePreviewCopyWithImpl<$Res, RecipePreview>;
  @useResult
  $Res call(
      {int id,
      String title,
      String? description,
      int? preparation_time,
      int? cooking_time,
      String? thumbnail_url,
      List<String>? tags,
      bool? is_favorite,
      DateTime? last_visited_at});
}

/// @nodoc
class _$RecipePreviewCopyWithImpl<$Res, $Val extends RecipePreview>
    implements $RecipePreviewCopyWith<$Res> {
  _$RecipePreviewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecipePreview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? preparation_time = freezed,
    Object? cooking_time = freezed,
    Object? thumbnail_url = freezed,
    Object? tags = freezed,
    Object? is_favorite = freezed,
    Object? last_visited_at = freezed,
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
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      preparation_time: freezed == preparation_time
          ? _value.preparation_time
          : preparation_time // ignore: cast_nullable_to_non_nullable
              as int?,
      cooking_time: freezed == cooking_time
          ? _value.cooking_time
          : cooking_time // ignore: cast_nullable_to_non_nullable
              as int?,
      thumbnail_url: freezed == thumbnail_url
          ? _value.thumbnail_url
          : thumbnail_url // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: freezed == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      is_favorite: freezed == is_favorite
          ? _value.is_favorite
          : is_favorite // ignore: cast_nullable_to_non_nullable
              as bool?,
      last_visited_at: freezed == last_visited_at
          ? _value.last_visited_at
          : last_visited_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecipePreviewImplCopyWith<$Res>
    implements $RecipePreviewCopyWith<$Res> {
  factory _$$RecipePreviewImplCopyWith(
          _$RecipePreviewImpl value, $Res Function(_$RecipePreviewImpl) then) =
      __$$RecipePreviewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String title,
      String? description,
      int? preparation_time,
      int? cooking_time,
      String? thumbnail_url,
      List<String>? tags,
      bool? is_favorite,
      DateTime? last_visited_at});
}

/// @nodoc
class __$$RecipePreviewImplCopyWithImpl<$Res>
    extends _$RecipePreviewCopyWithImpl<$Res, _$RecipePreviewImpl>
    implements _$$RecipePreviewImplCopyWith<$Res> {
  __$$RecipePreviewImplCopyWithImpl(
      _$RecipePreviewImpl _value, $Res Function(_$RecipePreviewImpl) _then)
      : super(_value, _then);

  /// Create a copy of RecipePreview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? description = freezed,
    Object? preparation_time = freezed,
    Object? cooking_time = freezed,
    Object? thumbnail_url = freezed,
    Object? tags = freezed,
    Object? is_favorite = freezed,
    Object? last_visited_at = freezed,
  }) {
    return _then(_$RecipePreviewImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      preparation_time: freezed == preparation_time
          ? _value.preparation_time
          : preparation_time // ignore: cast_nullable_to_non_nullable
              as int?,
      cooking_time: freezed == cooking_time
          ? _value.cooking_time
          : cooking_time // ignore: cast_nullable_to_non_nullable
              as int?,
      thumbnail_url: freezed == thumbnail_url
          ? _value.thumbnail_url
          : thumbnail_url // ignore: cast_nullable_to_non_nullable
              as String?,
      tags: freezed == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      is_favorite: freezed == is_favorite
          ? _value.is_favorite
          : is_favorite // ignore: cast_nullable_to_non_nullable
              as bool?,
      last_visited_at: freezed == last_visited_at
          ? _value.last_visited_at
          : last_visited_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecipePreviewImpl implements _RecipePreview {
  const _$RecipePreviewImpl(
      {required this.id,
      required this.title,
      this.description,
      this.preparation_time,
      this.cooking_time,
      this.thumbnail_url,
      final List<String>? tags,
      this.is_favorite,
      this.last_visited_at})
      : _tags = tags;

  factory _$RecipePreviewImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipePreviewImplFromJson(json);

  @override
  final int id;
  @override
  final String title;
  @override
  final String? description;
  @override
  final int? preparation_time;
  @override
  final int? cooking_time;
  @override
  final String? thumbnail_url;
  final List<String>? _tags;
  @override
  List<String>? get tags {
    final value = _tags;
    if (value == null) return null;
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  @override
  final bool? is_favorite;
  @override
  final DateTime? last_visited_at;

  @override
  String toString() {
    return 'RecipePreview(id: $id, title: $title, description: $description, preparation_time: $preparation_time, cooking_time: $cooking_time, thumbnail_url: $thumbnail_url, tags: $tags, is_favorite: $is_favorite, last_visited_at: $last_visited_at)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipePreviewImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.preparation_time, preparation_time) ||
                other.preparation_time == preparation_time) &&
            (identical(other.cooking_time, cooking_time) ||
                other.cooking_time == cooking_time) &&
            (identical(other.thumbnail_url, thumbnail_url) ||
                other.thumbnail_url == thumbnail_url) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.is_favorite, is_favorite) ||
                other.is_favorite == is_favorite) &&
            (identical(other.last_visited_at, last_visited_at) ||
                other.last_visited_at == last_visited_at));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      description,
      preparation_time,
      cooking_time,
      thumbnail_url,
      const DeepCollectionEquality().hash(_tags),
      is_favorite,
      last_visited_at);

  /// Create a copy of RecipePreview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipePreviewImplCopyWith<_$RecipePreviewImpl> get copyWith =>
      __$$RecipePreviewImplCopyWithImpl<_$RecipePreviewImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecipePreviewImplToJson(
      this,
    );
  }
}

abstract class _RecipePreview implements RecipePreview {
  const factory _RecipePreview(
      {required final int id,
      required final String title,
      final String? description,
      final int? preparation_time,
      final int? cooking_time,
      final String? thumbnail_url,
      final List<String>? tags,
      final bool? is_favorite,
      final DateTime? last_visited_at}) = _$RecipePreviewImpl;

  factory _RecipePreview.fromJson(Map<String, dynamic> json) =
      _$RecipePreviewImpl.fromJson;

  @override
  int get id;
  @override
  String get title;
  @override
  String? get description;
  @override
  int? get preparation_time;
  @override
  int? get cooking_time;
  @override
  String? get thumbnail_url;
  @override
  List<String>? get tags;
  @override
  bool? get is_favorite;
  @override
  DateTime? get last_visited_at;

  /// Create a copy of RecipePreview
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecipePreviewImplCopyWith<_$RecipePreviewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
