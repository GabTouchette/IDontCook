// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'module_payloads.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

HeroSuggestionPayload _$HeroSuggestionPayloadFromJson(
    Map<String, dynamic> json) {
  return _HeroSuggestionPayload.fromJson(json);
}

/// @nodoc
mixin _$HeroSuggestionPayload {
  RecipeSummary get recipe => throw _privateConstructorUsedError;
  String get tagline => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HeroSuggestionPayloadCopyWith<HeroSuggestionPayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HeroSuggestionPayloadCopyWith<$Res> {
  factory $HeroSuggestionPayloadCopyWith(HeroSuggestionPayload value,
          $Res Function(HeroSuggestionPayload) then) =
      _$HeroSuggestionPayloadCopyWithImpl<$Res, HeroSuggestionPayload>;
  @useResult
  $Res call({RecipeSummary recipe, String tagline});

  $RecipeSummaryCopyWith<$Res> get recipe;
}

/// @nodoc
class _$HeroSuggestionPayloadCopyWithImpl<$Res,
        $Val extends HeroSuggestionPayload>
    implements $HeroSuggestionPayloadCopyWith<$Res> {
  _$HeroSuggestionPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recipe = null,
    Object? tagline = null,
  }) {
    return _then(_value.copyWith(
      recipe: null == recipe
          ? _value.recipe
          : recipe // ignore: cast_nullable_to_non_nullable
              as RecipeSummary,
      tagline: null == tagline
          ? _value.tagline
          : tagline // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $RecipeSummaryCopyWith<$Res> get recipe {
    return $RecipeSummaryCopyWith<$Res>(_value.recipe, (value) {
      return _then(_value.copyWith(recipe: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$HeroSuggestionPayloadImplCopyWith<$Res>
    implements $HeroSuggestionPayloadCopyWith<$Res> {
  factory _$$HeroSuggestionPayloadImplCopyWith(
          _$HeroSuggestionPayloadImpl value,
          $Res Function(_$HeroSuggestionPayloadImpl) then) =
      __$$HeroSuggestionPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({RecipeSummary recipe, String tagline});

  @override
  $RecipeSummaryCopyWith<$Res> get recipe;
}

/// @nodoc
class __$$HeroSuggestionPayloadImplCopyWithImpl<$Res>
    extends _$HeroSuggestionPayloadCopyWithImpl<$Res,
        _$HeroSuggestionPayloadImpl>
    implements _$$HeroSuggestionPayloadImplCopyWith<$Res> {
  __$$HeroSuggestionPayloadImplCopyWithImpl(_$HeroSuggestionPayloadImpl _value,
      $Res Function(_$HeroSuggestionPayloadImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recipe = null,
    Object? tagline = null,
  }) {
    return _then(_$HeroSuggestionPayloadImpl(
      recipe: null == recipe
          ? _value.recipe
          : recipe // ignore: cast_nullable_to_non_nullable
              as RecipeSummary,
      tagline: null == tagline
          ? _value.tagline
          : tagline // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HeroSuggestionPayloadImpl implements _HeroSuggestionPayload {
  const _$HeroSuggestionPayloadImpl({required this.recipe, this.tagline = ''});

  factory _$HeroSuggestionPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$HeroSuggestionPayloadImplFromJson(json);

  @override
  final RecipeSummary recipe;
  @override
  @JsonKey()
  final String tagline;

  @override
  String toString() {
    return 'HeroSuggestionPayload(recipe: $recipe, tagline: $tagline)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HeroSuggestionPayloadImpl &&
            (identical(other.recipe, recipe) || other.recipe == recipe) &&
            (identical(other.tagline, tagline) || other.tagline == tagline));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, recipe, tagline);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HeroSuggestionPayloadImplCopyWith<_$HeroSuggestionPayloadImpl>
      get copyWith => __$$HeroSuggestionPayloadImplCopyWithImpl<
          _$HeroSuggestionPayloadImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HeroSuggestionPayloadImplToJson(
      this,
    );
  }
}

abstract class _HeroSuggestionPayload implements HeroSuggestionPayload {
  const factory _HeroSuggestionPayload(
      {required final RecipeSummary recipe,
      final String tagline}) = _$HeroSuggestionPayloadImpl;

  factory _HeroSuggestionPayload.fromJson(Map<String, dynamic> json) =
      _$HeroSuggestionPayloadImpl.fromJson;

  @override
  RecipeSummary get recipe;
  @override
  String get tagline;
  @override
  @JsonKey(ignore: true)
  _$$HeroSuggestionPayloadImplCopyWith<_$HeroSuggestionPayloadImpl>
      get copyWith => throw _privateConstructorUsedError;
}

CookAgainPayload _$CookAgainPayloadFromJson(Map<String, dynamic> json) {
  return _CookAgainPayload.fromJson(json);
}

/// @nodoc
mixin _$CookAgainPayload {
  RecipeSummary get recipe => throw _privateConstructorUsedError;
  DateTime? get saved_at => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CookAgainPayloadCopyWith<CookAgainPayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CookAgainPayloadCopyWith<$Res> {
  factory $CookAgainPayloadCopyWith(
          CookAgainPayload value, $Res Function(CookAgainPayload) then) =
      _$CookAgainPayloadCopyWithImpl<$Res, CookAgainPayload>;
  @useResult
  $Res call({RecipeSummary recipe, DateTime? saved_at});

  $RecipeSummaryCopyWith<$Res> get recipe;
}

/// @nodoc
class _$CookAgainPayloadCopyWithImpl<$Res, $Val extends CookAgainPayload>
    implements $CookAgainPayloadCopyWith<$Res> {
  _$CookAgainPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recipe = null,
    Object? saved_at = freezed,
  }) {
    return _then(_value.copyWith(
      recipe: null == recipe
          ? _value.recipe
          : recipe // ignore: cast_nullable_to_non_nullable
              as RecipeSummary,
      saved_at: freezed == saved_at
          ? _value.saved_at
          : saved_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $RecipeSummaryCopyWith<$Res> get recipe {
    return $RecipeSummaryCopyWith<$Res>(_value.recipe, (value) {
      return _then(_value.copyWith(recipe: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$CookAgainPayloadImplCopyWith<$Res>
    implements $CookAgainPayloadCopyWith<$Res> {
  factory _$$CookAgainPayloadImplCopyWith(_$CookAgainPayloadImpl value,
          $Res Function(_$CookAgainPayloadImpl) then) =
      __$$CookAgainPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({RecipeSummary recipe, DateTime? saved_at});

  @override
  $RecipeSummaryCopyWith<$Res> get recipe;
}

/// @nodoc
class __$$CookAgainPayloadImplCopyWithImpl<$Res>
    extends _$CookAgainPayloadCopyWithImpl<$Res, _$CookAgainPayloadImpl>
    implements _$$CookAgainPayloadImplCopyWith<$Res> {
  __$$CookAgainPayloadImplCopyWithImpl(_$CookAgainPayloadImpl _value,
      $Res Function(_$CookAgainPayloadImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recipe = null,
    Object? saved_at = freezed,
  }) {
    return _then(_$CookAgainPayloadImpl(
      recipe: null == recipe
          ? _value.recipe
          : recipe // ignore: cast_nullable_to_non_nullable
              as RecipeSummary,
      saved_at: freezed == saved_at
          ? _value.saved_at
          : saved_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CookAgainPayloadImpl implements _CookAgainPayload {
  const _$CookAgainPayloadImpl({required this.recipe, this.saved_at});

  factory _$CookAgainPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$CookAgainPayloadImplFromJson(json);

  @override
  final RecipeSummary recipe;
  @override
  final DateTime? saved_at;

  @override
  String toString() {
    return 'CookAgainPayload(recipe: $recipe, saved_at: $saved_at)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CookAgainPayloadImpl &&
            (identical(other.recipe, recipe) || other.recipe == recipe) &&
            (identical(other.saved_at, saved_at) ||
                other.saved_at == saved_at));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, recipe, saved_at);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CookAgainPayloadImplCopyWith<_$CookAgainPayloadImpl> get copyWith =>
      __$$CookAgainPayloadImplCopyWithImpl<_$CookAgainPayloadImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CookAgainPayloadImplToJson(
      this,
    );
  }
}

abstract class _CookAgainPayload implements CookAgainPayload {
  const factory _CookAgainPayload(
      {required final RecipeSummary recipe,
      final DateTime? saved_at}) = _$CookAgainPayloadImpl;

  factory _CookAgainPayload.fromJson(Map<String, dynamic> json) =
      _$CookAgainPayloadImpl.fromJson;

  @override
  RecipeSummary get recipe;
  @override
  DateTime? get saved_at;
  @override
  @JsonKey(ignore: true)
  _$$CookAgainPayloadImplCopyWith<_$CookAgainPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

PostAuthor _$PostAuthorFromJson(Map<String, dynamic> json) {
  return _PostAuthor.fromJson(json);
}

/// @nodoc
mixin _$PostAuthor {
  int get id => throw _privateConstructorUsedError;
  String get username => throw _privateConstructorUsedError;
  String? get avatar_url => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PostAuthorCopyWith<PostAuthor> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PostAuthorCopyWith<$Res> {
  factory $PostAuthorCopyWith(
          PostAuthor value, $Res Function(PostAuthor) then) =
      _$PostAuthorCopyWithImpl<$Res, PostAuthor>;
  @useResult
  $Res call({int id, String username, String? avatar_url});
}

/// @nodoc
class _$PostAuthorCopyWithImpl<$Res, $Val extends PostAuthor>
    implements $PostAuthorCopyWith<$Res> {
  _$PostAuthorCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? avatar_url = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      avatar_url: freezed == avatar_url
          ? _value.avatar_url
          : avatar_url // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PostAuthorImplCopyWith<$Res>
    implements $PostAuthorCopyWith<$Res> {
  factory _$$PostAuthorImplCopyWith(
          _$PostAuthorImpl value, $Res Function(_$PostAuthorImpl) then) =
      __$$PostAuthorImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int id, String username, String? avatar_url});
}

/// @nodoc
class __$$PostAuthorImplCopyWithImpl<$Res>
    extends _$PostAuthorCopyWithImpl<$Res, _$PostAuthorImpl>
    implements _$$PostAuthorImplCopyWith<$Res> {
  __$$PostAuthorImplCopyWithImpl(
      _$PostAuthorImpl _value, $Res Function(_$PostAuthorImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? username = null,
    Object? avatar_url = freezed,
  }) {
    return _then(_$PostAuthorImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      username: null == username
          ? _value.username
          : username // ignore: cast_nullable_to_non_nullable
              as String,
      avatar_url: freezed == avatar_url
          ? _value.avatar_url
          : avatar_url // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PostAuthorImpl implements _PostAuthor {
  const _$PostAuthorImpl(
      {required this.id, required this.username, this.avatar_url});

  factory _$PostAuthorImpl.fromJson(Map<String, dynamic> json) =>
      _$$PostAuthorImplFromJson(json);

  @override
  final int id;
  @override
  final String username;
  @override
  final String? avatar_url;

  @override
  String toString() {
    return 'PostAuthor(id: $id, username: $username, avatar_url: $avatar_url)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PostAuthorImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.username, username) ||
                other.username == username) &&
            (identical(other.avatar_url, avatar_url) ||
                other.avatar_url == avatar_url));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, username, avatar_url);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PostAuthorImplCopyWith<_$PostAuthorImpl> get copyWith =>
      __$$PostAuthorImplCopyWithImpl<_$PostAuthorImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PostAuthorImplToJson(
      this,
    );
  }
}

abstract class _PostAuthor implements PostAuthor {
  const factory _PostAuthor(
      {required final int id,
      required final String username,
      final String? avatar_url}) = _$PostAuthorImpl;

  factory _PostAuthor.fromJson(Map<String, dynamic> json) =
      _$PostAuthorImpl.fromJson;

  @override
  int get id;
  @override
  String get username;
  @override
  String? get avatar_url;
  @override
  @JsonKey(ignore: true)
  _$$PostAuthorImplCopyWith<_$PostAuthorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

FriendPostPayload _$FriendPostPayloadFromJson(Map<String, dynamic> json) {
  return _FriendPostPayload.fromJson(json);
}

/// @nodoc
mixin _$FriendPostPayload {
  int get post_id => throw _privateConstructorUsedError;
  PostAuthor get author => throw _privateConstructorUsedError;
  RecipeSummary? get recipe => throw _privateConstructorUsedError;
  String get preview_text => throw _privateConstructorUsedError;
  DateTime? get created_at => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $FriendPostPayloadCopyWith<FriendPostPayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FriendPostPayloadCopyWith<$Res> {
  factory $FriendPostPayloadCopyWith(
          FriendPostPayload value, $Res Function(FriendPostPayload) then) =
      _$FriendPostPayloadCopyWithImpl<$Res, FriendPostPayload>;
  @useResult
  $Res call(
      {int post_id,
      PostAuthor author,
      RecipeSummary? recipe,
      String preview_text,
      DateTime? created_at});

  $PostAuthorCopyWith<$Res> get author;
  $RecipeSummaryCopyWith<$Res>? get recipe;
}

/// @nodoc
class _$FriendPostPayloadCopyWithImpl<$Res, $Val extends FriendPostPayload>
    implements $FriendPostPayloadCopyWith<$Res> {
  _$FriendPostPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? post_id = null,
    Object? author = null,
    Object? recipe = freezed,
    Object? preview_text = null,
    Object? created_at = freezed,
  }) {
    return _then(_value.copyWith(
      post_id: null == post_id
          ? _value.post_id
          : post_id // ignore: cast_nullable_to_non_nullable
              as int,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as PostAuthor,
      recipe: freezed == recipe
          ? _value.recipe
          : recipe // ignore: cast_nullable_to_non_nullable
              as RecipeSummary?,
      preview_text: null == preview_text
          ? _value.preview_text
          : preview_text // ignore: cast_nullable_to_non_nullable
              as String,
      created_at: freezed == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $PostAuthorCopyWith<$Res> get author {
    return $PostAuthorCopyWith<$Res>(_value.author, (value) {
      return _then(_value.copyWith(author: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $RecipeSummaryCopyWith<$Res>? get recipe {
    if (_value.recipe == null) {
      return null;
    }

    return $RecipeSummaryCopyWith<$Res>(_value.recipe!, (value) {
      return _then(_value.copyWith(recipe: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$FriendPostPayloadImplCopyWith<$Res>
    implements $FriendPostPayloadCopyWith<$Res> {
  factory _$$FriendPostPayloadImplCopyWith(_$FriendPostPayloadImpl value,
          $Res Function(_$FriendPostPayloadImpl) then) =
      __$$FriendPostPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int post_id,
      PostAuthor author,
      RecipeSummary? recipe,
      String preview_text,
      DateTime? created_at});

  @override
  $PostAuthorCopyWith<$Res> get author;
  @override
  $RecipeSummaryCopyWith<$Res>? get recipe;
}

/// @nodoc
class __$$FriendPostPayloadImplCopyWithImpl<$Res>
    extends _$FriendPostPayloadCopyWithImpl<$Res, _$FriendPostPayloadImpl>
    implements _$$FriendPostPayloadImplCopyWith<$Res> {
  __$$FriendPostPayloadImplCopyWithImpl(_$FriendPostPayloadImpl _value,
      $Res Function(_$FriendPostPayloadImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? post_id = null,
    Object? author = null,
    Object? recipe = freezed,
    Object? preview_text = null,
    Object? created_at = freezed,
  }) {
    return _then(_$FriendPostPayloadImpl(
      post_id: null == post_id
          ? _value.post_id
          : post_id // ignore: cast_nullable_to_non_nullable
              as int,
      author: null == author
          ? _value.author
          : author // ignore: cast_nullable_to_non_nullable
              as PostAuthor,
      recipe: freezed == recipe
          ? _value.recipe
          : recipe // ignore: cast_nullable_to_non_nullable
              as RecipeSummary?,
      preview_text: null == preview_text
          ? _value.preview_text
          : preview_text // ignore: cast_nullable_to_non_nullable
              as String,
      created_at: freezed == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FriendPostPayloadImpl implements _FriendPostPayload {
  const _$FriendPostPayloadImpl(
      {required this.post_id,
      required this.author,
      this.recipe,
      this.preview_text = '',
      this.created_at});

  factory _$FriendPostPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$FriendPostPayloadImplFromJson(json);

  @override
  final int post_id;
  @override
  final PostAuthor author;
  @override
  final RecipeSummary? recipe;
  @override
  @JsonKey()
  final String preview_text;
  @override
  final DateTime? created_at;

  @override
  String toString() {
    return 'FriendPostPayload(post_id: $post_id, author: $author, recipe: $recipe, preview_text: $preview_text, created_at: $created_at)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FriendPostPayloadImpl &&
            (identical(other.post_id, post_id) || other.post_id == post_id) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.recipe, recipe) || other.recipe == recipe) &&
            (identical(other.preview_text, preview_text) ||
                other.preview_text == preview_text) &&
            (identical(other.created_at, created_at) ||
                other.created_at == created_at));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, post_id, author, recipe, preview_text, created_at);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FriendPostPayloadImplCopyWith<_$FriendPostPayloadImpl> get copyWith =>
      __$$FriendPostPayloadImplCopyWithImpl<_$FriendPostPayloadImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FriendPostPayloadImplToJson(
      this,
    );
  }
}

abstract class _FriendPostPayload implements FriendPostPayload {
  const factory _FriendPostPayload(
      {required final int post_id,
      required final PostAuthor author,
      final RecipeSummary? recipe,
      final String preview_text,
      final DateTime? created_at}) = _$FriendPostPayloadImpl;

  factory _FriendPostPayload.fromJson(Map<String, dynamic> json) =
      _$FriendPostPayloadImpl.fromJson;

  @override
  int get post_id;
  @override
  PostAuthor get author;
  @override
  RecipeSummary? get recipe;
  @override
  String get preview_text;
  @override
  DateTime? get created_at;
  @override
  @JsonKey(ignore: true)
  _$$FriendPostPayloadImplCopyWith<_$FriendPostPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MealPlanNudgePayload _$MealPlanNudgePayloadFromJson(Map<String, dynamic> json) {
  return _MealPlanNudgePayload.fromJson(json);
}

/// @nodoc
mixin _$MealPlanNudgePayload {
  String get week_start => throw _privateConstructorUsedError;
  int get planned_days => throw _privateConstructorUsedError;
  String get cta => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MealPlanNudgePayloadCopyWith<MealPlanNudgePayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MealPlanNudgePayloadCopyWith<$Res> {
  factory $MealPlanNudgePayloadCopyWith(MealPlanNudgePayload value,
          $Res Function(MealPlanNudgePayload) then) =
      _$MealPlanNudgePayloadCopyWithImpl<$Res, MealPlanNudgePayload>;
  @useResult
  $Res call({String week_start, int planned_days, String cta});
}

/// @nodoc
class _$MealPlanNudgePayloadCopyWithImpl<$Res,
        $Val extends MealPlanNudgePayload>
    implements $MealPlanNudgePayloadCopyWith<$Res> {
  _$MealPlanNudgePayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? week_start = null,
    Object? planned_days = null,
    Object? cta = null,
  }) {
    return _then(_value.copyWith(
      week_start: null == week_start
          ? _value.week_start
          : week_start // ignore: cast_nullable_to_non_nullable
              as String,
      planned_days: null == planned_days
          ? _value.planned_days
          : planned_days // ignore: cast_nullable_to_non_nullable
              as int,
      cta: null == cta
          ? _value.cta
          : cta // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MealPlanNudgePayloadImplCopyWith<$Res>
    implements $MealPlanNudgePayloadCopyWith<$Res> {
  factory _$$MealPlanNudgePayloadImplCopyWith(_$MealPlanNudgePayloadImpl value,
          $Res Function(_$MealPlanNudgePayloadImpl) then) =
      __$$MealPlanNudgePayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String week_start, int planned_days, String cta});
}

/// @nodoc
class __$$MealPlanNudgePayloadImplCopyWithImpl<$Res>
    extends _$MealPlanNudgePayloadCopyWithImpl<$Res, _$MealPlanNudgePayloadImpl>
    implements _$$MealPlanNudgePayloadImplCopyWith<$Res> {
  __$$MealPlanNudgePayloadImplCopyWithImpl(_$MealPlanNudgePayloadImpl _value,
      $Res Function(_$MealPlanNudgePayloadImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? week_start = null,
    Object? planned_days = null,
    Object? cta = null,
  }) {
    return _then(_$MealPlanNudgePayloadImpl(
      week_start: null == week_start
          ? _value.week_start
          : week_start // ignore: cast_nullable_to_non_nullable
              as String,
      planned_days: null == planned_days
          ? _value.planned_days
          : planned_days // ignore: cast_nullable_to_non_nullable
              as int,
      cta: null == cta
          ? _value.cta
          : cta // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MealPlanNudgePayloadImpl implements _MealPlanNudgePayload {
  const _$MealPlanNudgePayloadImpl(
      {this.week_start = '', this.planned_days = 0, this.cta = ''});

  factory _$MealPlanNudgePayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$MealPlanNudgePayloadImplFromJson(json);

  @override
  @JsonKey()
  final String week_start;
  @override
  @JsonKey()
  final int planned_days;
  @override
  @JsonKey()
  final String cta;

  @override
  String toString() {
    return 'MealPlanNudgePayload(week_start: $week_start, planned_days: $planned_days, cta: $cta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MealPlanNudgePayloadImpl &&
            (identical(other.week_start, week_start) ||
                other.week_start == week_start) &&
            (identical(other.planned_days, planned_days) ||
                other.planned_days == planned_days) &&
            (identical(other.cta, cta) || other.cta == cta));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, week_start, planned_days, cta);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MealPlanNudgePayloadImplCopyWith<_$MealPlanNudgePayloadImpl>
      get copyWith =>
          __$$MealPlanNudgePayloadImplCopyWithImpl<_$MealPlanNudgePayloadImpl>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MealPlanNudgePayloadImplToJson(
      this,
    );
  }
}

abstract class _MealPlanNudgePayload implements MealPlanNudgePayload {
  const factory _MealPlanNudgePayload(
      {final String week_start,
      final int planned_days,
      final String cta}) = _$MealPlanNudgePayloadImpl;

  factory _MealPlanNudgePayload.fromJson(Map<String, dynamic> json) =
      _$MealPlanNudgePayloadImpl.fromJson;

  @override
  String get week_start;
  @override
  int get planned_days;
  @override
  String get cta;
  @override
  @JsonKey(ignore: true)
  _$$MealPlanNudgePayloadImplCopyWith<_$MealPlanNudgePayloadImpl>
      get copyWith => throw _privateConstructorUsedError;
}

GroceryShortcutPayload _$GroceryShortcutPayloadFromJson(
    Map<String, dynamic> json) {
  return _GroceryShortcutPayload.fromJson(json);
}

/// @nodoc
mixin _$GroceryShortcutPayload {
  int get item_count => throw _privateConstructorUsedError;
  String get cta => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GroceryShortcutPayloadCopyWith<GroceryShortcutPayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GroceryShortcutPayloadCopyWith<$Res> {
  factory $GroceryShortcutPayloadCopyWith(GroceryShortcutPayload value,
          $Res Function(GroceryShortcutPayload) then) =
      _$GroceryShortcutPayloadCopyWithImpl<$Res, GroceryShortcutPayload>;
  @useResult
  $Res call({int item_count, String cta});
}

/// @nodoc
class _$GroceryShortcutPayloadCopyWithImpl<$Res,
        $Val extends GroceryShortcutPayload>
    implements $GroceryShortcutPayloadCopyWith<$Res> {
  _$GroceryShortcutPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? item_count = null,
    Object? cta = null,
  }) {
    return _then(_value.copyWith(
      item_count: null == item_count
          ? _value.item_count
          : item_count // ignore: cast_nullable_to_non_nullable
              as int,
      cta: null == cta
          ? _value.cta
          : cta // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GroceryShortcutPayloadImplCopyWith<$Res>
    implements $GroceryShortcutPayloadCopyWith<$Res> {
  factory _$$GroceryShortcutPayloadImplCopyWith(
          _$GroceryShortcutPayloadImpl value,
          $Res Function(_$GroceryShortcutPayloadImpl) then) =
      __$$GroceryShortcutPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int item_count, String cta});
}

/// @nodoc
class __$$GroceryShortcutPayloadImplCopyWithImpl<$Res>
    extends _$GroceryShortcutPayloadCopyWithImpl<$Res,
        _$GroceryShortcutPayloadImpl>
    implements _$$GroceryShortcutPayloadImplCopyWith<$Res> {
  __$$GroceryShortcutPayloadImplCopyWithImpl(
      _$GroceryShortcutPayloadImpl _value,
      $Res Function(_$GroceryShortcutPayloadImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? item_count = null,
    Object? cta = null,
  }) {
    return _then(_$GroceryShortcutPayloadImpl(
      item_count: null == item_count
          ? _value.item_count
          : item_count // ignore: cast_nullable_to_non_nullable
              as int,
      cta: null == cta
          ? _value.cta
          : cta // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GroceryShortcutPayloadImpl implements _GroceryShortcutPayload {
  const _$GroceryShortcutPayloadImpl({this.item_count = 0, this.cta = ''});

  factory _$GroceryShortcutPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$GroceryShortcutPayloadImplFromJson(json);

  @override
  @JsonKey()
  final int item_count;
  @override
  @JsonKey()
  final String cta;

  @override
  String toString() {
    return 'GroceryShortcutPayload(item_count: $item_count, cta: $cta)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GroceryShortcutPayloadImpl &&
            (identical(other.item_count, item_count) ||
                other.item_count == item_count) &&
            (identical(other.cta, cta) || other.cta == cta));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, item_count, cta);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GroceryShortcutPayloadImplCopyWith<_$GroceryShortcutPayloadImpl>
      get copyWith => __$$GroceryShortcutPayloadImplCopyWithImpl<
          _$GroceryShortcutPayloadImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GroceryShortcutPayloadImplToJson(
      this,
    );
  }
}

abstract class _GroceryShortcutPayload implements GroceryShortcutPayload {
  const factory _GroceryShortcutPayload(
      {final int item_count, final String cta}) = _$GroceryShortcutPayloadImpl;

  factory _GroceryShortcutPayload.fromJson(Map<String, dynamic> json) =
      _$GroceryShortcutPayloadImpl.fromJson;

  @override
  int get item_count;
  @override
  String get cta;
  @override
  @JsonKey(ignore: true)
  _$$GroceryShortcutPayloadImplCopyWith<_$GroceryShortcutPayloadImpl>
      get copyWith => throw _privateConstructorUsedError;
}

ChatPromptPayload _$ChatPromptPayloadFromJson(Map<String, dynamic> json) {
  return _ChatPromptPayload.fromJson(json);
}

/// @nodoc
mixin _$ChatPromptPayload {
  String get prompt_text => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ChatPromptPayloadCopyWith<ChatPromptPayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatPromptPayloadCopyWith<$Res> {
  factory $ChatPromptPayloadCopyWith(
          ChatPromptPayload value, $Res Function(ChatPromptPayload) then) =
      _$ChatPromptPayloadCopyWithImpl<$Res, ChatPromptPayload>;
  @useResult
  $Res call({String prompt_text});
}

/// @nodoc
class _$ChatPromptPayloadCopyWithImpl<$Res, $Val extends ChatPromptPayload>
    implements $ChatPromptPayloadCopyWith<$Res> {
  _$ChatPromptPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? prompt_text = null,
  }) {
    return _then(_value.copyWith(
      prompt_text: null == prompt_text
          ? _value.prompt_text
          : prompt_text // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ChatPromptPayloadImplCopyWith<$Res>
    implements $ChatPromptPayloadCopyWith<$Res> {
  factory _$$ChatPromptPayloadImplCopyWith(_$ChatPromptPayloadImpl value,
          $Res Function(_$ChatPromptPayloadImpl) then) =
      __$$ChatPromptPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String prompt_text});
}

/// @nodoc
class __$$ChatPromptPayloadImplCopyWithImpl<$Res>
    extends _$ChatPromptPayloadCopyWithImpl<$Res, _$ChatPromptPayloadImpl>
    implements _$$ChatPromptPayloadImplCopyWith<$Res> {
  __$$ChatPromptPayloadImplCopyWithImpl(_$ChatPromptPayloadImpl _value,
      $Res Function(_$ChatPromptPayloadImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? prompt_text = null,
  }) {
    return _then(_$ChatPromptPayloadImpl(
      prompt_text: null == prompt_text
          ? _value.prompt_text
          : prompt_text // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatPromptPayloadImpl implements _ChatPromptPayload {
  const _$ChatPromptPayloadImpl({this.prompt_text = ''});

  factory _$ChatPromptPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatPromptPayloadImplFromJson(json);

  @override
  @JsonKey()
  final String prompt_text;

  @override
  String toString() {
    return 'ChatPromptPayload(prompt_text: $prompt_text)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatPromptPayloadImpl &&
            (identical(other.prompt_text, prompt_text) ||
                other.prompt_text == prompt_text));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, prompt_text);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatPromptPayloadImplCopyWith<_$ChatPromptPayloadImpl> get copyWith =>
      __$$ChatPromptPayloadImplCopyWithImpl<_$ChatPromptPayloadImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatPromptPayloadImplToJson(
      this,
    );
  }
}

abstract class _ChatPromptPayload implements ChatPromptPayload {
  const factory _ChatPromptPayload({final String prompt_text}) =
      _$ChatPromptPayloadImpl;

  factory _ChatPromptPayload.fromJson(Map<String, dynamic> json) =
      _$ChatPromptPayloadImpl.fromJson;

  @override
  String get prompt_text;
  @override
  @JsonKey(ignore: true)
  _$$ChatPromptPayloadImplCopyWith<_$ChatPromptPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

ExploreRailPayload _$ExploreRailPayloadFromJson(Map<String, dynamic> json) {
  return _ExploreRailPayload.fromJson(json);
}

/// @nodoc
mixin _$ExploreRailPayload {
  String get title => throw _privateConstructorUsedError;
  List<RecipeSummary> get recipes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ExploreRailPayloadCopyWith<ExploreRailPayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExploreRailPayloadCopyWith<$Res> {
  factory $ExploreRailPayloadCopyWith(
          ExploreRailPayload value, $Res Function(ExploreRailPayload) then) =
      _$ExploreRailPayloadCopyWithImpl<$Res, ExploreRailPayload>;
  @useResult
  $Res call({String title, List<RecipeSummary> recipes});
}

/// @nodoc
class _$ExploreRailPayloadCopyWithImpl<$Res, $Val extends ExploreRailPayload>
    implements $ExploreRailPayloadCopyWith<$Res> {
  _$ExploreRailPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? recipes = null,
  }) {
    return _then(_value.copyWith(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      recipes: null == recipes
          ? _value.recipes
          : recipes // ignore: cast_nullable_to_non_nullable
              as List<RecipeSummary>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ExploreRailPayloadImplCopyWith<$Res>
    implements $ExploreRailPayloadCopyWith<$Res> {
  factory _$$ExploreRailPayloadImplCopyWith(_$ExploreRailPayloadImpl value,
          $Res Function(_$ExploreRailPayloadImpl) then) =
      __$$ExploreRailPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String title, List<RecipeSummary> recipes});
}

/// @nodoc
class __$$ExploreRailPayloadImplCopyWithImpl<$Res>
    extends _$ExploreRailPayloadCopyWithImpl<$Res, _$ExploreRailPayloadImpl>
    implements _$$ExploreRailPayloadImplCopyWith<$Res> {
  __$$ExploreRailPayloadImplCopyWithImpl(_$ExploreRailPayloadImpl _value,
      $Res Function(_$ExploreRailPayloadImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? title = null,
    Object? recipes = null,
  }) {
    return _then(_$ExploreRailPayloadImpl(
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      recipes: null == recipes
          ? _value._recipes
          : recipes // ignore: cast_nullable_to_non_nullable
              as List<RecipeSummary>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ExploreRailPayloadImpl implements _ExploreRailPayload {
  const _$ExploreRailPayloadImpl(
      {this.title = '',
      final List<RecipeSummary> recipes = const <RecipeSummary>[]})
      : _recipes = recipes;

  factory _$ExploreRailPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$ExploreRailPayloadImplFromJson(json);

  @override
  @JsonKey()
  final String title;
  final List<RecipeSummary> _recipes;
  @override
  @JsonKey()
  List<RecipeSummary> get recipes {
    if (_recipes is EqualUnmodifiableListView) return _recipes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recipes);
  }

  @override
  String toString() {
    return 'ExploreRailPayload(title: $title, recipes: $recipes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExploreRailPayloadImpl &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other._recipes, _recipes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, title, const DeepCollectionEquality().hash(_recipes));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ExploreRailPayloadImplCopyWith<_$ExploreRailPayloadImpl> get copyWith =>
      __$$ExploreRailPayloadImplCopyWithImpl<_$ExploreRailPayloadImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ExploreRailPayloadImplToJson(
      this,
    );
  }
}

abstract class _ExploreRailPayload implements ExploreRailPayload {
  const factory _ExploreRailPayload(
      {final String title,
      final List<RecipeSummary> recipes}) = _$ExploreRailPayloadImpl;

  factory _ExploreRailPayload.fromJson(Map<String, dynamic> json) =
      _$ExploreRailPayloadImpl.fromJson;

  @override
  String get title;
  @override
  List<RecipeSummary> get recipes;
  @override
  @JsonKey(ignore: true)
  _$$ExploreRailPayloadImplCopyWith<_$ExploreRailPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

EventCardPayload _$EventCardPayloadFromJson(Map<String, dynamic> json) {
  return _EventCardPayload.fromJson(json);
}

/// @nodoc
mixin _$EventCardPayload {
  String get event_slug => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  String? get image_url => throw _privateConstructorUsedError;
  String? get cta => throw _privateConstructorUsedError;
  List<RecipeSummary> get recipes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $EventCardPayloadCopyWith<EventCardPayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EventCardPayloadCopyWith<$Res> {
  factory $EventCardPayloadCopyWith(
          EventCardPayload value, $Res Function(EventCardPayload) then) =
      _$EventCardPayloadCopyWithImpl<$Res, EventCardPayload>;
  @useResult
  $Res call(
      {String event_slug,
      String title,
      String body,
      String? image_url,
      String? cta,
      List<RecipeSummary> recipes});
}

/// @nodoc
class _$EventCardPayloadCopyWithImpl<$Res, $Val extends EventCardPayload>
    implements $EventCardPayloadCopyWith<$Res> {
  _$EventCardPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? event_slug = null,
    Object? title = null,
    Object? body = null,
    Object? image_url = freezed,
    Object? cta = freezed,
    Object? recipes = null,
  }) {
    return _then(_value.copyWith(
      event_slug: null == event_slug
          ? _value.event_slug
          : event_slug // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      image_url: freezed == image_url
          ? _value.image_url
          : image_url // ignore: cast_nullable_to_non_nullable
              as String?,
      cta: freezed == cta
          ? _value.cta
          : cta // ignore: cast_nullable_to_non_nullable
              as String?,
      recipes: null == recipes
          ? _value.recipes
          : recipes // ignore: cast_nullable_to_non_nullable
              as List<RecipeSummary>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$EventCardPayloadImplCopyWith<$Res>
    implements $EventCardPayloadCopyWith<$Res> {
  factory _$$EventCardPayloadImplCopyWith(_$EventCardPayloadImpl value,
          $Res Function(_$EventCardPayloadImpl) then) =
      __$$EventCardPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String event_slug,
      String title,
      String body,
      String? image_url,
      String? cta,
      List<RecipeSummary> recipes});
}

/// @nodoc
class __$$EventCardPayloadImplCopyWithImpl<$Res>
    extends _$EventCardPayloadCopyWithImpl<$Res, _$EventCardPayloadImpl>
    implements _$$EventCardPayloadImplCopyWith<$Res> {
  __$$EventCardPayloadImplCopyWithImpl(_$EventCardPayloadImpl _value,
      $Res Function(_$EventCardPayloadImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? event_slug = null,
    Object? title = null,
    Object? body = null,
    Object? image_url = freezed,
    Object? cta = freezed,
    Object? recipes = null,
  }) {
    return _then(_$EventCardPayloadImpl(
      event_slug: null == event_slug
          ? _value.event_slug
          : event_slug // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      body: null == body
          ? _value.body
          : body // ignore: cast_nullable_to_non_nullable
              as String,
      image_url: freezed == image_url
          ? _value.image_url
          : image_url // ignore: cast_nullable_to_non_nullable
              as String?,
      cta: freezed == cta
          ? _value.cta
          : cta // ignore: cast_nullable_to_non_nullable
              as String?,
      recipes: null == recipes
          ? _value._recipes
          : recipes // ignore: cast_nullable_to_non_nullable
              as List<RecipeSummary>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$EventCardPayloadImpl implements _EventCardPayload {
  const _$EventCardPayloadImpl(
      {this.event_slug = '',
      this.title = '',
      this.body = '',
      this.image_url,
      this.cta,
      final List<RecipeSummary> recipes = const <RecipeSummary>[]})
      : _recipes = recipes;

  factory _$EventCardPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$EventCardPayloadImplFromJson(json);

  @override
  @JsonKey()
  final String event_slug;
  @override
  @JsonKey()
  final String title;
  @override
  @JsonKey()
  final String body;
  @override
  final String? image_url;
  @override
  final String? cta;
  final List<RecipeSummary> _recipes;
  @override
  @JsonKey()
  List<RecipeSummary> get recipes {
    if (_recipes is EqualUnmodifiableListView) return _recipes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recipes);
  }

  @override
  String toString() {
    return 'EventCardPayload(event_slug: $event_slug, title: $title, body: $body, image_url: $image_url, cta: $cta, recipes: $recipes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EventCardPayloadImpl &&
            (identical(other.event_slug, event_slug) ||
                other.event_slug == event_slug) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.image_url, image_url) ||
                other.image_url == image_url) &&
            (identical(other.cta, cta) || other.cta == cta) &&
            const DeepCollectionEquality().equals(other._recipes, _recipes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, event_slug, title, body,
      image_url, cta, const DeepCollectionEquality().hash(_recipes));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$EventCardPayloadImplCopyWith<_$EventCardPayloadImpl> get copyWith =>
      __$$EventCardPayloadImplCopyWithImpl<_$EventCardPayloadImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EventCardPayloadImplToJson(
      this,
    );
  }
}

abstract class _EventCardPayload implements EventCardPayload {
  const factory _EventCardPayload(
      {final String event_slug,
      final String title,
      final String body,
      final String? image_url,
      final String? cta,
      final List<RecipeSummary> recipes}) = _$EventCardPayloadImpl;

  factory _EventCardPayload.fromJson(Map<String, dynamic> json) =
      _$EventCardPayloadImpl.fromJson;

  @override
  String get event_slug;
  @override
  String get title;
  @override
  String get body;
  @override
  String? get image_url;
  @override
  String? get cta;
  @override
  List<RecipeSummary> get recipes;
  @override
  @JsonKey(ignore: true)
  _$$EventCardPayloadImplCopyWith<_$EventCardPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DealItem _$DealItemFromJson(Map<String, dynamic> json) {
  return _DealItem.fromJson(json);
}

/// @nodoc
mixin _$DealItem {
  String get name => throw _privateConstructorUsedError;
  String? get name_alt => throw _privateConstructorUsedError;
  String get brand => throw _privateConstructorUsedError;
  String? get price => throw _privateConstructorUsedError;
  num? get price_value => throw _privateConstructorUsedError;
  int? get discount => throw _privateConstructorUsedError;
  String? get image_url => throw _privateConstructorUsedError;
  String? get valid_to => throw _privateConstructorUsedError;
  String get merchant => throw _privateConstructorUsedError;
  int? get distance_m => throw _privateConstructorUsedError;
  num? get savings => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DealItemCopyWith<DealItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DealItemCopyWith<$Res> {
  factory $DealItemCopyWith(DealItem value, $Res Function(DealItem) then) =
      _$DealItemCopyWithImpl<$Res, DealItem>;
  @useResult
  $Res call(
      {String name,
      String? name_alt,
      String brand,
      String? price,
      num? price_value,
      int? discount,
      String? image_url,
      String? valid_to,
      String merchant,
      int? distance_m,
      num? savings});
}

/// @nodoc
class _$DealItemCopyWithImpl<$Res, $Val extends DealItem>
    implements $DealItemCopyWith<$Res> {
  _$DealItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? name_alt = freezed,
    Object? brand = null,
    Object? price = freezed,
    Object? price_value = freezed,
    Object? discount = freezed,
    Object? image_url = freezed,
    Object? valid_to = freezed,
    Object? merchant = null,
    Object? distance_m = freezed,
    Object? savings = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      name_alt: freezed == name_alt
          ? _value.name_alt
          : name_alt // ignore: cast_nullable_to_non_nullable
              as String?,
      brand: null == brand
          ? _value.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as String,
      price: freezed == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as String?,
      price_value: freezed == price_value
          ? _value.price_value
          : price_value // ignore: cast_nullable_to_non_nullable
              as num?,
      discount: freezed == discount
          ? _value.discount
          : discount // ignore: cast_nullable_to_non_nullable
              as int?,
      image_url: freezed == image_url
          ? _value.image_url
          : image_url // ignore: cast_nullable_to_non_nullable
              as String?,
      valid_to: freezed == valid_to
          ? _value.valid_to
          : valid_to // ignore: cast_nullable_to_non_nullable
              as String?,
      merchant: null == merchant
          ? _value.merchant
          : merchant // ignore: cast_nullable_to_non_nullable
              as String,
      distance_m: freezed == distance_m
          ? _value.distance_m
          : distance_m // ignore: cast_nullable_to_non_nullable
              as int?,
      savings: freezed == savings
          ? _value.savings
          : savings // ignore: cast_nullable_to_non_nullable
              as num?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DealItemImplCopyWith<$Res>
    implements $DealItemCopyWith<$Res> {
  factory _$$DealItemImplCopyWith(
          _$DealItemImpl value, $Res Function(_$DealItemImpl) then) =
      __$$DealItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String? name_alt,
      String brand,
      String? price,
      num? price_value,
      int? discount,
      String? image_url,
      String? valid_to,
      String merchant,
      int? distance_m,
      num? savings});
}

/// @nodoc
class __$$DealItemImplCopyWithImpl<$Res>
    extends _$DealItemCopyWithImpl<$Res, _$DealItemImpl>
    implements _$$DealItemImplCopyWith<$Res> {
  __$$DealItemImplCopyWithImpl(
      _$DealItemImpl _value, $Res Function(_$DealItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? name_alt = freezed,
    Object? brand = null,
    Object? price = freezed,
    Object? price_value = freezed,
    Object? discount = freezed,
    Object? image_url = freezed,
    Object? valid_to = freezed,
    Object? merchant = null,
    Object? distance_m = freezed,
    Object? savings = freezed,
  }) {
    return _then(_$DealItemImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      name_alt: freezed == name_alt
          ? _value.name_alt
          : name_alt // ignore: cast_nullable_to_non_nullable
              as String?,
      brand: null == brand
          ? _value.brand
          : brand // ignore: cast_nullable_to_non_nullable
              as String,
      price: freezed == price
          ? _value.price
          : price // ignore: cast_nullable_to_non_nullable
              as String?,
      price_value: freezed == price_value
          ? _value.price_value
          : price_value // ignore: cast_nullable_to_non_nullable
              as num?,
      discount: freezed == discount
          ? _value.discount
          : discount // ignore: cast_nullable_to_non_nullable
              as int?,
      image_url: freezed == image_url
          ? _value.image_url
          : image_url // ignore: cast_nullable_to_non_nullable
              as String?,
      valid_to: freezed == valid_to
          ? _value.valid_to
          : valid_to // ignore: cast_nullable_to_non_nullable
              as String?,
      merchant: null == merchant
          ? _value.merchant
          : merchant // ignore: cast_nullable_to_non_nullable
              as String,
      distance_m: freezed == distance_m
          ? _value.distance_m
          : distance_m // ignore: cast_nullable_to_non_nullable
              as int?,
      savings: freezed == savings
          ? _value.savings
          : savings // ignore: cast_nullable_to_non_nullable
              as num?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DealItemImpl extends _DealItem {
  const _$DealItemImpl(
      {this.name = '',
      this.name_alt,
      this.brand = '',
      this.price,
      this.price_value,
      this.discount,
      this.image_url,
      this.valid_to,
      this.merchant = '',
      this.distance_m,
      this.savings})
      : super._();

  factory _$DealItemImpl.fromJson(Map<String, dynamic> json) =>
      _$$DealItemImplFromJson(json);

  @override
  @JsonKey()
  final String name;
  @override
  final String? name_alt;
  @override
  @JsonKey()
  final String brand;
  @override
  final String? price;
  @override
  final num? price_value;
  @override
  final int? discount;
  @override
  final String? image_url;
  @override
  final String? valid_to;
  @override
  @JsonKey()
  final String merchant;
  @override
  final int? distance_m;
  @override
  final num? savings;

  @override
  String toString() {
    return 'DealItem(name: $name, name_alt: $name_alt, brand: $brand, price: $price, price_value: $price_value, discount: $discount, image_url: $image_url, valid_to: $valid_to, merchant: $merchant, distance_m: $distance_m, savings: $savings)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DealItemImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.name_alt, name_alt) ||
                other.name_alt == name_alt) &&
            (identical(other.brand, brand) || other.brand == brand) &&
            (identical(other.price, price) || other.price == price) &&
            (identical(other.price_value, price_value) ||
                other.price_value == price_value) &&
            (identical(other.discount, discount) ||
                other.discount == discount) &&
            (identical(other.image_url, image_url) ||
                other.image_url == image_url) &&
            (identical(other.valid_to, valid_to) ||
                other.valid_to == valid_to) &&
            (identical(other.merchant, merchant) ||
                other.merchant == merchant) &&
            (identical(other.distance_m, distance_m) ||
                other.distance_m == distance_m) &&
            (identical(other.savings, savings) || other.savings == savings));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      name,
      name_alt,
      brand,
      price,
      price_value,
      discount,
      image_url,
      valid_to,
      merchant,
      distance_m,
      savings);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DealItemImplCopyWith<_$DealItemImpl> get copyWith =>
      __$$DealItemImplCopyWithImpl<_$DealItemImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DealItemImplToJson(
      this,
    );
  }
}

abstract class _DealItem extends DealItem {
  const factory _DealItem(
      {final String name,
      final String? name_alt,
      final String brand,
      final String? price,
      final num? price_value,
      final int? discount,
      final String? image_url,
      final String? valid_to,
      final String merchant,
      final int? distance_m,
      final num? savings}) = _$DealItemImpl;
  const _DealItem._() : super._();

  factory _DealItem.fromJson(Map<String, dynamic> json) =
      _$DealItemImpl.fromJson;

  @override
  String get name;
  @override
  String? get name_alt;
  @override
  String get brand;
  @override
  String? get price;
  @override
  num? get price_value;
  @override
  int? get discount;
  @override
  String? get image_url;
  @override
  String? get valid_to;
  @override
  String get merchant;
  @override
  int? get distance_m;
  @override
  num? get savings;
  @override
  @JsonKey(ignore: true)
  _$$DealItemImplCopyWith<_$DealItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DealStore _$DealStoreFromJson(Map<String, dynamic> json) {
  return _DealStore.fromJson(json);
}

/// @nodoc
mixin _$DealStore {
  String get merchant => throw _privateConstructorUsedError;
  int get merchant_id => throw _privateConstructorUsedError;
  String? get merchant_logo => throw _privateConstructorUsedError;
  int? get distance_m => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DealStoreCopyWith<DealStore> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DealStoreCopyWith<$Res> {
  factory $DealStoreCopyWith(DealStore value, $Res Function(DealStore) then) =
      _$DealStoreCopyWithImpl<$Res, DealStore>;
  @useResult
  $Res call(
      {String merchant,
      int merchant_id,
      String? merchant_logo,
      int? distance_m});
}

/// @nodoc
class _$DealStoreCopyWithImpl<$Res, $Val extends DealStore>
    implements $DealStoreCopyWith<$Res> {
  _$DealStoreCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? merchant = null,
    Object? merchant_id = null,
    Object? merchant_logo = freezed,
    Object? distance_m = freezed,
  }) {
    return _then(_value.copyWith(
      merchant: null == merchant
          ? _value.merchant
          : merchant // ignore: cast_nullable_to_non_nullable
              as String,
      merchant_id: null == merchant_id
          ? _value.merchant_id
          : merchant_id // ignore: cast_nullable_to_non_nullable
              as int,
      merchant_logo: freezed == merchant_logo
          ? _value.merchant_logo
          : merchant_logo // ignore: cast_nullable_to_non_nullable
              as String?,
      distance_m: freezed == distance_m
          ? _value.distance_m
          : distance_m // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DealStoreImplCopyWith<$Res>
    implements $DealStoreCopyWith<$Res> {
  factory _$$DealStoreImplCopyWith(
          _$DealStoreImpl value, $Res Function(_$DealStoreImpl) then) =
      __$$DealStoreImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String merchant,
      int merchant_id,
      String? merchant_logo,
      int? distance_m});
}

/// @nodoc
class __$$DealStoreImplCopyWithImpl<$Res>
    extends _$DealStoreCopyWithImpl<$Res, _$DealStoreImpl>
    implements _$$DealStoreImplCopyWith<$Res> {
  __$$DealStoreImplCopyWithImpl(
      _$DealStoreImpl _value, $Res Function(_$DealStoreImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? merchant = null,
    Object? merchant_id = null,
    Object? merchant_logo = freezed,
    Object? distance_m = freezed,
  }) {
    return _then(_$DealStoreImpl(
      merchant: null == merchant
          ? _value.merchant
          : merchant // ignore: cast_nullable_to_non_nullable
              as String,
      merchant_id: null == merchant_id
          ? _value.merchant_id
          : merchant_id // ignore: cast_nullable_to_non_nullable
              as int,
      merchant_logo: freezed == merchant_logo
          ? _value.merchant_logo
          : merchant_logo // ignore: cast_nullable_to_non_nullable
              as String?,
      distance_m: freezed == distance_m
          ? _value.distance_m
          : distance_m // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DealStoreImpl implements _DealStore {
  const _$DealStoreImpl(
      {this.merchant = '',
      this.merchant_id = 0,
      this.merchant_logo,
      this.distance_m});

  factory _$DealStoreImpl.fromJson(Map<String, dynamic> json) =>
      _$$DealStoreImplFromJson(json);

  @override
  @JsonKey()
  final String merchant;
  @override
  @JsonKey()
  final int merchant_id;
  @override
  final String? merchant_logo;
  @override
  final int? distance_m;

  @override
  String toString() {
    return 'DealStore(merchant: $merchant, merchant_id: $merchant_id, merchant_logo: $merchant_logo, distance_m: $distance_m)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DealStoreImpl &&
            (identical(other.merchant, merchant) ||
                other.merchant == merchant) &&
            (identical(other.merchant_id, merchant_id) ||
                other.merchant_id == merchant_id) &&
            (identical(other.merchant_logo, merchant_logo) ||
                other.merchant_logo == merchant_logo) &&
            (identical(other.distance_m, distance_m) ||
                other.distance_m == distance_m));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, merchant, merchant_id, merchant_logo, distance_m);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DealStoreImplCopyWith<_$DealStoreImpl> get copyWith =>
      __$$DealStoreImplCopyWithImpl<_$DealStoreImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DealStoreImplToJson(
      this,
    );
  }
}

abstract class _DealStore implements DealStore {
  const factory _DealStore(
      {final String merchant,
      final int merchant_id,
      final String? merchant_logo,
      final int? distance_m}) = _$DealStoreImpl;

  factory _DealStore.fromJson(Map<String, dynamic> json) =
      _$DealStoreImpl.fromJson;

  @override
  String get merchant;
  @override
  int get merchant_id;
  @override
  String? get merchant_logo;
  @override
  int? get distance_m;
  @override
  @JsonKey(ignore: true)
  _$$DealStoreImplCopyWith<_$DealStoreImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DealsRailPayload _$DealsRailPayloadFromJson(Map<String, dynamic> json) {
  return _DealsRailPayload.fromJson(json);
}

/// @nodoc
mixin _$DealsRailPayload {
  String get state => throw _privateConstructorUsedError;
  String? get postal_code => throw _privateConstructorUsedError;
  List<DealStore> get stores => throw _privateConstructorUsedError;
  int get total_count => throw _privateConstructorUsedError;
  List<DealItem> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $DealsRailPayloadCopyWith<DealsRailPayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DealsRailPayloadCopyWith<$Res> {
  factory $DealsRailPayloadCopyWith(
          DealsRailPayload value, $Res Function(DealsRailPayload) then) =
      _$DealsRailPayloadCopyWithImpl<$Res, DealsRailPayload>;
  @useResult
  $Res call(
      {String state,
      String? postal_code,
      List<DealStore> stores,
      int total_count,
      List<DealItem> items});
}

/// @nodoc
class _$DealsRailPayloadCopyWithImpl<$Res, $Val extends DealsRailPayload>
    implements $DealsRailPayloadCopyWith<$Res> {
  _$DealsRailPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = null,
    Object? postal_code = freezed,
    Object? stores = null,
    Object? total_count = null,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      postal_code: freezed == postal_code
          ? _value.postal_code
          : postal_code // ignore: cast_nullable_to_non_nullable
              as String?,
      stores: null == stores
          ? _value.stores
          : stores // ignore: cast_nullable_to_non_nullable
              as List<DealStore>,
      total_count: null == total_count
          ? _value.total_count
          : total_count // ignore: cast_nullable_to_non_nullable
              as int,
      items: null == items
          ? _value.items
          : items // ignore: cast_nullable_to_non_nullable
              as List<DealItem>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DealsRailPayloadImplCopyWith<$Res>
    implements $DealsRailPayloadCopyWith<$Res> {
  factory _$$DealsRailPayloadImplCopyWith(_$DealsRailPayloadImpl value,
          $Res Function(_$DealsRailPayloadImpl) then) =
      __$$DealsRailPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String state,
      String? postal_code,
      List<DealStore> stores,
      int total_count,
      List<DealItem> items});
}

/// @nodoc
class __$$DealsRailPayloadImplCopyWithImpl<$Res>
    extends _$DealsRailPayloadCopyWithImpl<$Res, _$DealsRailPayloadImpl>
    implements _$$DealsRailPayloadImplCopyWith<$Res> {
  __$$DealsRailPayloadImplCopyWithImpl(_$DealsRailPayloadImpl _value,
      $Res Function(_$DealsRailPayloadImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? state = null,
    Object? postal_code = freezed,
    Object? stores = null,
    Object? total_count = null,
    Object? items = null,
  }) {
    return _then(_$DealsRailPayloadImpl(
      state: null == state
          ? _value.state
          : state // ignore: cast_nullable_to_non_nullable
              as String,
      postal_code: freezed == postal_code
          ? _value.postal_code
          : postal_code // ignore: cast_nullable_to_non_nullable
              as String?,
      stores: null == stores
          ? _value._stores
          : stores // ignore: cast_nullable_to_non_nullable
              as List<DealStore>,
      total_count: null == total_count
          ? _value.total_count
          : total_count // ignore: cast_nullable_to_non_nullable
              as int,
      items: null == items
          ? _value._items
          : items // ignore: cast_nullable_to_non_nullable
              as List<DealItem>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DealsRailPayloadImpl extends _DealsRailPayload {
  const _$DealsRailPayloadImpl(
      {this.state = 'ready',
      this.postal_code,
      final List<DealStore> stores = const <DealStore>[],
      this.total_count = 0,
      final List<DealItem> items = const <DealItem>[]})
      : _stores = stores,
        _items = items,
        super._();

  factory _$DealsRailPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$DealsRailPayloadImplFromJson(json);

  @override
  @JsonKey()
  final String state;
  @override
  final String? postal_code;
  final List<DealStore> _stores;
  @override
  @JsonKey()
  List<DealStore> get stores {
    if (_stores is EqualUnmodifiableListView) return _stores;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_stores);
  }

  @override
  @JsonKey()
  final int total_count;
  final List<DealItem> _items;
  @override
  @JsonKey()
  List<DealItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  @override
  String toString() {
    return 'DealsRailPayload(state: $state, postal_code: $postal_code, stores: $stores, total_count: $total_count, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DealsRailPayloadImpl &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.postal_code, postal_code) ||
                other.postal_code == postal_code) &&
            const DeepCollectionEquality().equals(other._stores, _stores) &&
            (identical(other.total_count, total_count) ||
                other.total_count == total_count) &&
            const DeepCollectionEquality().equals(other._items, _items));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      state,
      postal_code,
      const DeepCollectionEquality().hash(_stores),
      total_count,
      const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DealsRailPayloadImplCopyWith<_$DealsRailPayloadImpl> get copyWith =>
      __$$DealsRailPayloadImplCopyWithImpl<_$DealsRailPayloadImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DealsRailPayloadImplToJson(
      this,
    );
  }
}

abstract class _DealsRailPayload extends DealsRailPayload {
  const factory _DealsRailPayload(
      {final String state,
      final String? postal_code,
      final List<DealStore> stores,
      final int total_count,
      final List<DealItem> items}) = _$DealsRailPayloadImpl;
  const _DealsRailPayload._() : super._();

  factory _DealsRailPayload.fromJson(Map<String, dynamic> json) =
      _$DealsRailPayloadImpl.fromJson;

  @override
  String get state;
  @override
  String? get postal_code;
  @override
  List<DealStore> get stores;
  @override
  int get total_count;
  @override
  List<DealItem> get items;
  @override
  @JsonKey(ignore: true)
  _$$DealsRailPayloadImplCopyWith<_$DealsRailPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MoodOption _$MoodOptionFromJson(Map<String, dynamic> json) {
  return _MoodOption.fromJson(json);
}

/// @nodoc
mixin _$MoodOption {
  String get mood => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  String get emoji => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MoodOptionCopyWith<MoodOption> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MoodOptionCopyWith<$Res> {
  factory $MoodOptionCopyWith(
          MoodOption value, $Res Function(MoodOption) then) =
      _$MoodOptionCopyWithImpl<$Res, MoodOption>;
  @useResult
  $Res call({String mood, String label, String emoji});
}

/// @nodoc
class _$MoodOptionCopyWithImpl<$Res, $Val extends MoodOption>
    implements $MoodOptionCopyWith<$Res> {
  _$MoodOptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mood = null,
    Object? label = null,
    Object? emoji = null,
  }) {
    return _then(_value.copyWith(
      mood: null == mood
          ? _value.mood
          : mood // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      emoji: null == emoji
          ? _value.emoji
          : emoji // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MoodOptionImplCopyWith<$Res>
    implements $MoodOptionCopyWith<$Res> {
  factory _$$MoodOptionImplCopyWith(
          _$MoodOptionImpl value, $Res Function(_$MoodOptionImpl) then) =
      __$$MoodOptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String mood, String label, String emoji});
}

/// @nodoc
class __$$MoodOptionImplCopyWithImpl<$Res>
    extends _$MoodOptionCopyWithImpl<$Res, _$MoodOptionImpl>
    implements _$$MoodOptionImplCopyWith<$Res> {
  __$$MoodOptionImplCopyWithImpl(
      _$MoodOptionImpl _value, $Res Function(_$MoodOptionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mood = null,
    Object? label = null,
    Object? emoji = null,
  }) {
    return _then(_$MoodOptionImpl(
      mood: null == mood
          ? _value.mood
          : mood // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      emoji: null == emoji
          ? _value.emoji
          : emoji // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MoodOptionImpl extends _MoodOption {
  const _$MoodOptionImpl({this.mood = '', this.label = '', this.emoji = ''})
      : super._();

  factory _$MoodOptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$MoodOptionImplFromJson(json);

  @override
  @JsonKey()
  final String mood;
  @override
  @JsonKey()
  final String label;
  @override
  @JsonKey()
  final String emoji;

  @override
  String toString() {
    return 'MoodOption(mood: $mood, label: $label, emoji: $emoji)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MoodOptionImpl &&
            (identical(other.mood, mood) || other.mood == mood) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.emoji, emoji) || other.emoji == emoji));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, mood, label, emoji);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MoodOptionImplCopyWith<_$MoodOptionImpl> get copyWith =>
      __$$MoodOptionImplCopyWithImpl<_$MoodOptionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MoodOptionImplToJson(
      this,
    );
  }
}

abstract class _MoodOption extends MoodOption {
  const factory _MoodOption(
      {final String mood,
      final String label,
      final String emoji}) = _$MoodOptionImpl;
  const _MoodOption._() : super._();

  factory _MoodOption.fromJson(Map<String, dynamic> json) =
      _$MoodOptionImpl.fromJson;

  @override
  String get mood;
  @override
  String get label;
  @override
  String get emoji;
  @override
  @JsonKey(ignore: true)
  _$$MoodOptionImplCopyWith<_$MoodOptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MoodQuestionPayload _$MoodQuestionPayloadFromJson(Map<String, dynamic> json) {
  return _MoodQuestionPayload.fromJson(json);
}

/// @nodoc
mixin _$MoodQuestionPayload {
  String get question => throw _privateConstructorUsedError;
  List<MoodOption> get options => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MoodQuestionPayloadCopyWith<MoodQuestionPayload> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MoodQuestionPayloadCopyWith<$Res> {
  factory $MoodQuestionPayloadCopyWith(
          MoodQuestionPayload value, $Res Function(MoodQuestionPayload) then) =
      _$MoodQuestionPayloadCopyWithImpl<$Res, MoodQuestionPayload>;
  @useResult
  $Res call({String question, List<MoodOption> options});
}

/// @nodoc
class _$MoodQuestionPayloadCopyWithImpl<$Res, $Val extends MoodQuestionPayload>
    implements $MoodQuestionPayloadCopyWith<$Res> {
  _$MoodQuestionPayloadCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? question = null,
    Object? options = null,
  }) {
    return _then(_value.copyWith(
      question: null == question
          ? _value.question
          : question // ignore: cast_nullable_to_non_nullable
              as String,
      options: null == options
          ? _value.options
          : options // ignore: cast_nullable_to_non_nullable
              as List<MoodOption>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MoodQuestionPayloadImplCopyWith<$Res>
    implements $MoodQuestionPayloadCopyWith<$Res> {
  factory _$$MoodQuestionPayloadImplCopyWith(_$MoodQuestionPayloadImpl value,
          $Res Function(_$MoodQuestionPayloadImpl) then) =
      __$$MoodQuestionPayloadImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String question, List<MoodOption> options});
}

/// @nodoc
class __$$MoodQuestionPayloadImplCopyWithImpl<$Res>
    extends _$MoodQuestionPayloadCopyWithImpl<$Res, _$MoodQuestionPayloadImpl>
    implements _$$MoodQuestionPayloadImplCopyWith<$Res> {
  __$$MoodQuestionPayloadImplCopyWithImpl(_$MoodQuestionPayloadImpl _value,
      $Res Function(_$MoodQuestionPayloadImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? question = null,
    Object? options = null,
  }) {
    return _then(_$MoodQuestionPayloadImpl(
      question: null == question
          ? _value.question
          : question // ignore: cast_nullable_to_non_nullable
              as String,
      options: null == options
          ? _value._options
          : options // ignore: cast_nullable_to_non_nullable
              as List<MoodOption>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MoodQuestionPayloadImpl implements _MoodQuestionPayload {
  const _$MoodQuestionPayloadImpl(
      {this.question = '',
      final List<MoodOption> options = const <MoodOption>[]})
      : _options = options;

  factory _$MoodQuestionPayloadImpl.fromJson(Map<String, dynamic> json) =>
      _$$MoodQuestionPayloadImplFromJson(json);

  @override
  @JsonKey()
  final String question;
  final List<MoodOption> _options;
  @override
  @JsonKey()
  List<MoodOption> get options {
    if (_options is EqualUnmodifiableListView) return _options;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_options);
  }

  @override
  String toString() {
    return 'MoodQuestionPayload(question: $question, options: $options)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MoodQuestionPayloadImpl &&
            (identical(other.question, question) ||
                other.question == question) &&
            const DeepCollectionEquality().equals(other._options, _options));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, question, const DeepCollectionEquality().hash(_options));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MoodQuestionPayloadImplCopyWith<_$MoodQuestionPayloadImpl> get copyWith =>
      __$$MoodQuestionPayloadImplCopyWithImpl<_$MoodQuestionPayloadImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MoodQuestionPayloadImplToJson(
      this,
    );
  }
}

abstract class _MoodQuestionPayload implements MoodQuestionPayload {
  const factory _MoodQuestionPayload(
      {final String question,
      final List<MoodOption> options}) = _$MoodQuestionPayloadImpl;

  factory _MoodQuestionPayload.fromJson(Map<String, dynamic> json) =
      _$MoodQuestionPayloadImpl.fromJson;

  @override
  String get question;
  @override
  List<MoodOption> get options;
  @override
  @JsonKey(ignore: true)
  _$$MoodQuestionPayloadImplCopyWith<_$MoodQuestionPayloadImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
