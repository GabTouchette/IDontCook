// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'post.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Post _$PostFromJson(Map<String, dynamic> json) {
  return _Post.fromJson(json);
}

/// @nodoc
mixin _$Post {
  int get id => throw _privateConstructorUsedError;
  User get user => throw _privateConstructorUsedError;
  int? get recipe_id => throw _privateConstructorUsedError;
  String? get recipe_title => throw _privateConstructorUsedError;
  String? get recipe_description => throw _privateConstructorUsedError;
  String? get recipe_image_url => throw _privateConstructorUsedError;
  String? get content => throw _privateConstructorUsedError;
  DateTime? get created_at => throw _privateConstructorUsedError;
  DateTime? get updated_at => throw _privateConstructorUsedError;
  int get upvote_count => throw _privateConstructorUsedError;
  int get downvote_count => throw _privateConstructorUsedError;

  /// Serializes this Post to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Post
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PostCopyWith<Post> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostCopyWith<$Res> {
  factory $PostCopyWith(Post value, $Res Function(Post) then) =
      _$PostCopyWithImpl<$Res, Post>;
  @useResult
  $Res call(
      {int id,
      User user,
      int? recipe_id,
      String? recipe_title,
      String? recipe_description,
      String? recipe_image_url,
      String? content,
      DateTime? created_at,
      DateTime? updated_at,
      int upvote_count,
      int downvote_count});

  $UserCopyWith<$Res> get user;
}

/// @nodoc
class _$PostCopyWithImpl<$Res, $Val extends Post>
    implements $PostCopyWith<$Res> {
  _$PostCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Post
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? user = null,
    Object? recipe_id = freezed,
    Object? recipe_title = freezed,
    Object? recipe_description = freezed,
    Object? recipe_image_url = freezed,
    Object? content = freezed,
    Object? created_at = freezed,
    Object? updated_at = freezed,
    Object? upvote_count = null,
    Object? downvote_count = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as User,
      recipe_id: freezed == recipe_id
          ? _value.recipe_id
          : recipe_id // ignore: cast_nullable_to_non_nullable
              as int?,
      recipe_title: freezed == recipe_title
          ? _value.recipe_title
          : recipe_title // ignore: cast_nullable_to_non_nullable
              as String?,
      recipe_description: freezed == recipe_description
          ? _value.recipe_description
          : recipe_description // ignore: cast_nullable_to_non_nullable
              as String?,
      recipe_image_url: freezed == recipe_image_url
          ? _value.recipe_image_url
          : recipe_image_url // ignore: cast_nullable_to_non_nullable
              as String?,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String?,
      created_at: freezed == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updated_at: freezed == updated_at
          ? _value.updated_at
          : updated_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      upvote_count: null == upvote_count
          ? _value.upvote_count
          : upvote_count // ignore: cast_nullable_to_non_nullable
              as int,
      downvote_count: null == downvote_count
          ? _value.downvote_count
          : downvote_count // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }

  /// Create a copy of Post
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $UserCopyWith<$Res> get user {
    return $UserCopyWith<$Res>(_value.user, (value) {
      return _then(_value.copyWith(user: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$PostImplCopyWith<$Res> implements $PostCopyWith<$Res> {
  factory _$$PostImplCopyWith(
          _$PostImpl value, $Res Function(_$PostImpl) then) =
      __$$PostImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      User user,
      int? recipe_id,
      String? recipe_title,
      String? recipe_description,
      String? recipe_image_url,
      String? content,
      DateTime? created_at,
      DateTime? updated_at,
      int upvote_count,
      int downvote_count});

  @override
  $UserCopyWith<$Res> get user;
}

/// @nodoc
class __$$PostImplCopyWithImpl<$Res>
    extends _$PostCopyWithImpl<$Res, _$PostImpl>
    implements _$$PostImplCopyWith<$Res> {
  __$$PostImplCopyWithImpl(_$PostImpl _value, $Res Function(_$PostImpl) _then)
      : super(_value, _then);

  /// Create a copy of Post
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? user = null,
    Object? recipe_id = freezed,
    Object? recipe_title = freezed,
    Object? recipe_description = freezed,
    Object? recipe_image_url = freezed,
    Object? content = freezed,
    Object? created_at = freezed,
    Object? updated_at = freezed,
    Object? upvote_count = null,
    Object? downvote_count = null,
  }) {
    return _then(_$PostImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      user: null == user
          ? _value.user
          : user // ignore: cast_nullable_to_non_nullable
              as User,
      recipe_id: freezed == recipe_id
          ? _value.recipe_id
          : recipe_id // ignore: cast_nullable_to_non_nullable
              as int?,
      recipe_title: freezed == recipe_title
          ? _value.recipe_title
          : recipe_title // ignore: cast_nullable_to_non_nullable
              as String?,
      recipe_description: freezed == recipe_description
          ? _value.recipe_description
          : recipe_description // ignore: cast_nullable_to_non_nullable
              as String?,
      recipe_image_url: freezed == recipe_image_url
          ? _value.recipe_image_url
          : recipe_image_url // ignore: cast_nullable_to_non_nullable
              as String?,
      content: freezed == content
          ? _value.content
          : content // ignore: cast_nullable_to_non_nullable
              as String?,
      created_at: freezed == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updated_at: freezed == updated_at
          ? _value.updated_at
          : updated_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      upvote_count: null == upvote_count
          ? _value.upvote_count
          : upvote_count // ignore: cast_nullable_to_non_nullable
              as int,
      downvote_count: null == downvote_count
          ? _value.downvote_count
          : downvote_count // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PostImpl implements _Post {
  _$PostImpl(
      {required this.id,
      required this.user,
      this.recipe_id,
      this.recipe_title,
      this.recipe_description,
      this.recipe_image_url,
      this.content,
      this.created_at,
      this.updated_at,
      this.upvote_count = 0,
      this.downvote_count = 0});

  factory _$PostImpl.fromJson(Map<String, dynamic> json) =>
      _$$PostImplFromJson(json);

  @override
  final int id;
  @override
  final User user;
  @override
  final int? recipe_id;
  @override
  final String? recipe_title;
  @override
  final String? recipe_description;
  @override
  final String? recipe_image_url;
  @override
  final String? content;
  @override
  final DateTime? created_at;
  @override
  final DateTime? updated_at;
  @override
  @JsonKey()
  final int upvote_count;
  @override
  @JsonKey()
  final int downvote_count;

  @override
  String toString() {
    return 'Post(id: $id, user: $user, recipe_id: $recipe_id, recipe_title: $recipe_title, recipe_description: $recipe_description, recipe_image_url: $recipe_image_url, content: $content, created_at: $created_at, updated_at: $updated_at, upvote_count: $upvote_count, downvote_count: $downvote_count)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.user, user) || other.user == user) &&
            (identical(other.recipe_id, recipe_id) ||
                other.recipe_id == recipe_id) &&
            (identical(other.recipe_title, recipe_title) ||
                other.recipe_title == recipe_title) &&
            (identical(other.recipe_description, recipe_description) ||
                other.recipe_description == recipe_description) &&
            (identical(other.recipe_image_url, recipe_image_url) ||
                other.recipe_image_url == recipe_image_url) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.created_at, created_at) ||
                other.created_at == created_at) &&
            (identical(other.updated_at, updated_at) ||
                other.updated_at == updated_at) &&
            (identical(other.upvote_count, upvote_count) ||
                other.upvote_count == upvote_count) &&
            (identical(other.downvote_count, downvote_count) ||
                other.downvote_count == downvote_count));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      user,
      recipe_id,
      recipe_title,
      recipe_description,
      recipe_image_url,
      content,
      created_at,
      updated_at,
      upvote_count,
      downvote_count);

  /// Create a copy of Post
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PostImplCopyWith<_$PostImpl> get copyWith =>
      __$$PostImplCopyWithImpl<_$PostImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PostImplToJson(
      this,
    );
  }
}

abstract class _Post implements Post {
  factory _Post(
      {required final int id,
      required final User user,
      final int? recipe_id,
      final String? recipe_title,
      final String? recipe_description,
      final String? recipe_image_url,
      final String? content,
      final DateTime? created_at,
      final DateTime? updated_at,
      final int upvote_count,
      final int downvote_count}) = _$PostImpl;

  factory _Post.fromJson(Map<String, dynamic> json) = _$PostImpl.fromJson;

  @override
  int get id;
  @override
  User get user;
  @override
  int? get recipe_id;
  @override
  String? get recipe_title;
  @override
  String? get recipe_description;
  @override
  String? get recipe_image_url;
  @override
  String? get content;
  @override
  DateTime? get created_at;
  @override
  DateTime? get updated_at;
  @override
  int get upvote_count;
  @override
  int get downvote_count;

  /// Create a copy of Post
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PostImplCopyWith<_$PostImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
