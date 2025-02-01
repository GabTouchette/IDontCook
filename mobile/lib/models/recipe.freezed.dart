// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recipe.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Recipe _$RecipeFromJson(Map<String, dynamic> json) {
  return _Recipe.fromJson(json);
}

/// @nodoc
mixin _$Recipe {
  int get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  List<Ingredient> get ingredients => throw _privateConstructorUsedError;
  List<String> get instructions => throw _privateConstructorUsedError;
  int? get cooking_time => throw _privateConstructorUsedError;
  int? get preparation_time => throw _privateConstructorUsedError;
  List<String>? get tags => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get image_url => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  DateTime? get created_at => throw _privateConstructorUsedError;

  /// Serializes this Recipe to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Recipe
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecipeCopyWith<Recipe> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecipeCopyWith<$Res> {
  factory $RecipeCopyWith(Recipe value, $Res Function(Recipe) then) =
      _$RecipeCopyWithImpl<$Res, Recipe>;
  @useResult
  $Res call(
      {int id,
      String title,
      List<Ingredient> ingredients,
      List<String> instructions,
      int? cooking_time,
      int? preparation_time,
      List<String>? tags,
      String? description,
      String? image_url,
      String? notes,
      DateTime? created_at});
}

/// @nodoc
class _$RecipeCopyWithImpl<$Res, $Val extends Recipe>
    implements $RecipeCopyWith<$Res> {
  _$RecipeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Recipe
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? ingredients = null,
    Object? instructions = null,
    Object? cooking_time = freezed,
    Object? preparation_time = freezed,
    Object? tags = freezed,
    Object? description = freezed,
    Object? image_url = freezed,
    Object? notes = freezed,
    Object? created_at = freezed,
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
      ingredients: null == ingredients
          ? _value.ingredients
          : ingredients // ignore: cast_nullable_to_non_nullable
              as List<Ingredient>,
      instructions: null == instructions
          ? _value.instructions
          : instructions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      cooking_time: freezed == cooking_time
          ? _value.cooking_time
          : cooking_time // ignore: cast_nullable_to_non_nullable
              as int?,
      preparation_time: freezed == preparation_time
          ? _value.preparation_time
          : preparation_time // ignore: cast_nullable_to_non_nullable
              as int?,
      tags: freezed == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      image_url: freezed == image_url
          ? _value.image_url
          : image_url // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      created_at: freezed == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecipeImplCopyWith<$Res> implements $RecipeCopyWith<$Res> {
  factory _$$RecipeImplCopyWith(
          _$RecipeImpl value, $Res Function(_$RecipeImpl) then) =
      __$$RecipeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      String title,
      List<Ingredient> ingredients,
      List<String> instructions,
      int? cooking_time,
      int? preparation_time,
      List<String>? tags,
      String? description,
      String? image_url,
      String? notes,
      DateTime? created_at});
}

/// @nodoc
class __$$RecipeImplCopyWithImpl<$Res>
    extends _$RecipeCopyWithImpl<$Res, _$RecipeImpl>
    implements _$$RecipeImplCopyWith<$Res> {
  __$$RecipeImplCopyWithImpl(
      _$RecipeImpl _value, $Res Function(_$RecipeImpl) _then)
      : super(_value, _then);

  /// Create a copy of Recipe
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? ingredients = null,
    Object? instructions = null,
    Object? cooking_time = freezed,
    Object? preparation_time = freezed,
    Object? tags = freezed,
    Object? description = freezed,
    Object? image_url = freezed,
    Object? notes = freezed,
    Object? created_at = freezed,
  }) {
    return _then(_$RecipeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      ingredients: null == ingredients
          ? _value._ingredients
          : ingredients // ignore: cast_nullable_to_non_nullable
              as List<Ingredient>,
      instructions: null == instructions
          ? _value._instructions
          : instructions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      cooking_time: freezed == cooking_time
          ? _value.cooking_time
          : cooking_time // ignore: cast_nullable_to_non_nullable
              as int?,
      preparation_time: freezed == preparation_time
          ? _value.preparation_time
          : preparation_time // ignore: cast_nullable_to_non_nullable
              as int?,
      tags: freezed == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      description: freezed == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String?,
      image_url: freezed == image_url
          ? _value.image_url
          : image_url // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      created_at: freezed == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecipeImpl implements _Recipe {
  const _$RecipeImpl(
      {this.id = 0,
      this.title = "",
      final List<Ingredient> ingredients = const [],
      final List<String> instructions = const [],
      this.cooking_time,
      this.preparation_time,
      final List<String>? tags,
      this.description,
      this.image_url,
      this.notes,
      this.created_at})
      : _ingredients = ingredients,
        _instructions = instructions,
        _tags = tags;

  factory _$RecipeImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipeImplFromJson(json);

  @override
  @JsonKey()
  final int id;
  @override
  @JsonKey()
  final String title;
  final List<Ingredient> _ingredients;
  @override
  @JsonKey()
  List<Ingredient> get ingredients {
    if (_ingredients is EqualUnmodifiableListView) return _ingredients;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ingredients);
  }

  final List<String> _instructions;
  @override
  @JsonKey()
  List<String> get instructions {
    if (_instructions is EqualUnmodifiableListView) return _instructions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_instructions);
  }

  @override
  final int? cooking_time;
  @override
  final int? preparation_time;
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
  final String? description;
  @override
  final String? image_url;
  @override
  final String? notes;
  @override
  final DateTime? created_at;

  @override
  String toString() {
    return 'Recipe(id: $id, title: $title, ingredients: $ingredients, instructions: $instructions, cooking_time: $cooking_time, preparation_time: $preparation_time, tags: $tags, description: $description, image_url: $image_url, notes: $notes, created_at: $created_at)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality()
                .equals(other._ingredients, _ingredients) &&
            const DeepCollectionEquality()
                .equals(other._instructions, _instructions) &&
            (identical(other.cooking_time, cooking_time) ||
                other.cooking_time == cooking_time) &&
            (identical(other.preparation_time, preparation_time) ||
                other.preparation_time == preparation_time) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.image_url, image_url) ||
                other.image_url == image_url) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.created_at, created_at) ||
                other.created_at == created_at));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      const DeepCollectionEquality().hash(_ingredients),
      const DeepCollectionEquality().hash(_instructions),
      cooking_time,
      preparation_time,
      const DeepCollectionEquality().hash(_tags),
      description,
      image_url,
      notes,
      created_at);

  /// Create a copy of Recipe
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipeImplCopyWith<_$RecipeImpl> get copyWith =>
      __$$RecipeImplCopyWithImpl<_$RecipeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecipeImplToJson(
      this,
    );
  }
}

abstract class _Recipe implements Recipe {
  const factory _Recipe(
      {final int id,
      final String title,
      final List<Ingredient> ingredients,
      final List<String> instructions,
      final int? cooking_time,
      final int? preparation_time,
      final List<String>? tags,
      final String? description,
      final String? image_url,
      final String? notes,
      final DateTime? created_at}) = _$RecipeImpl;

  factory _Recipe.fromJson(Map<String, dynamic> json) = _$RecipeImpl.fromJson;

  @override
  int get id;
  @override
  String get title;
  @override
  List<Ingredient> get ingredients;
  @override
  List<String> get instructions;
  @override
  int? get cooking_time;
  @override
  int? get preparation_time;
  @override
  List<String>? get tags;
  @override
  String? get description;
  @override
  String? get image_url;
  @override
  String? get notes;
  @override
  DateTime? get created_at;

  /// Create a copy of Recipe
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecipeImplCopyWith<_$RecipeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
