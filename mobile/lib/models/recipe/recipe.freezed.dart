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
  int? get parent_id => throw _privateConstructorUsedError;
  int? get cooking_time => throw _privateConstructorUsedError;
  int? get preparation_time => throw _privateConstructorUsedError;
  int? get servings => throw _privateConstructorUsedError;
  List<String>? get tags => throw _privateConstructorUsedError;
  String? get description => throw _privateConstructorUsedError;
  String? get image_url => throw _privateConstructorUsedError;
  String? get thumbnail_url => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  bool? get is_favorite => throw _privateConstructorUsedError;
  bool? get is_saved => throw _privateConstructorUsedError;
  bool? get is_formatted => throw _privateConstructorUsedError;
  DateTime? get created_at => throw _privateConstructorUsedError;
  User? get created_by => throw _privateConstructorUsedError;
  DateTime? get last_visited_at => throw _privateConstructorUsedError;
  double? get calories => throw _privateConstructorUsedError;
  double? get protein => throw _privateConstructorUsedError;
  double? get fat => throw _privateConstructorUsedError;
  double? get carbs => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
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
      int? parent_id,
      int? cooking_time,
      int? preparation_time,
      int? servings,
      List<String>? tags,
      String? description,
      String? image_url,
      String? thumbnail_url,
      String? notes,
      bool? is_favorite,
      bool? is_saved,
      bool? is_formatted,
      DateTime? created_at,
      User? created_by,
      DateTime? last_visited_at,
      double? calories,
      double? protein,
      double? fat,
      double? carbs});

  $UserCopyWith<$Res>? get created_by;
}

/// @nodoc
class _$RecipeCopyWithImpl<$Res, $Val extends Recipe>
    implements $RecipeCopyWith<$Res> {
  _$RecipeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? ingredients = null,
    Object? instructions = null,
    Object? parent_id = freezed,
    Object? cooking_time = freezed,
    Object? preparation_time = freezed,
    Object? servings = freezed,
    Object? tags = freezed,
    Object? description = freezed,
    Object? image_url = freezed,
    Object? thumbnail_url = freezed,
    Object? notes = freezed,
    Object? is_favorite = freezed,
    Object? is_saved = freezed,
    Object? is_formatted = freezed,
    Object? created_at = freezed,
    Object? created_by = freezed,
    Object? last_visited_at = freezed,
    Object? calories = freezed,
    Object? protein = freezed,
    Object? fat = freezed,
    Object? carbs = freezed,
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
      parent_id: freezed == parent_id
          ? _value.parent_id
          : parent_id // ignore: cast_nullable_to_non_nullable
              as int?,
      cooking_time: freezed == cooking_time
          ? _value.cooking_time
          : cooking_time // ignore: cast_nullable_to_non_nullable
              as int?,
      preparation_time: freezed == preparation_time
          ? _value.preparation_time
          : preparation_time // ignore: cast_nullable_to_non_nullable
              as int?,
      servings: freezed == servings
          ? _value.servings
          : servings // ignore: cast_nullable_to_non_nullable
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
      thumbnail_url: freezed == thumbnail_url
          ? _value.thumbnail_url
          : thumbnail_url // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      is_favorite: freezed == is_favorite
          ? _value.is_favorite
          : is_favorite // ignore: cast_nullable_to_non_nullable
              as bool?,
      is_saved: freezed == is_saved
          ? _value.is_saved
          : is_saved // ignore: cast_nullable_to_non_nullable
              as bool?,
      is_formatted: freezed == is_formatted
          ? _value.is_formatted
          : is_formatted // ignore: cast_nullable_to_non_nullable
              as bool?,
      created_at: freezed == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      created_by: freezed == created_by
          ? _value.created_by
          : created_by // ignore: cast_nullable_to_non_nullable
              as User?,
      last_visited_at: freezed == last_visited_at
          ? _value.last_visited_at
          : last_visited_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      calories: freezed == calories
          ? _value.calories
          : calories // ignore: cast_nullable_to_non_nullable
              as double?,
      protein: freezed == protein
          ? _value.protein
          : protein // ignore: cast_nullable_to_non_nullable
              as double?,
      fat: freezed == fat
          ? _value.fat
          : fat // ignore: cast_nullable_to_non_nullable
              as double?,
      carbs: freezed == carbs
          ? _value.carbs
          : carbs // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $UserCopyWith<$Res>? get created_by {
    if (_value.created_by == null) {
      return null;
    }

    return $UserCopyWith<$Res>(_value.created_by!, (value) {
      return _then(_value.copyWith(created_by: value) as $Val);
    });
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
      int? parent_id,
      int? cooking_time,
      int? preparation_time,
      int? servings,
      List<String>? tags,
      String? description,
      String? image_url,
      String? thumbnail_url,
      String? notes,
      bool? is_favorite,
      bool? is_saved,
      bool? is_formatted,
      DateTime? created_at,
      User? created_by,
      DateTime? last_visited_at,
      double? calories,
      double? protein,
      double? fat,
      double? carbs});

  @override
  $UserCopyWith<$Res>? get created_by;
}

/// @nodoc
class __$$RecipeImplCopyWithImpl<$Res>
    extends _$RecipeCopyWithImpl<$Res, _$RecipeImpl>
    implements _$$RecipeImplCopyWith<$Res> {
  __$$RecipeImplCopyWithImpl(
      _$RecipeImpl _value, $Res Function(_$RecipeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? ingredients = null,
    Object? instructions = null,
    Object? parent_id = freezed,
    Object? cooking_time = freezed,
    Object? preparation_time = freezed,
    Object? servings = freezed,
    Object? tags = freezed,
    Object? description = freezed,
    Object? image_url = freezed,
    Object? thumbnail_url = freezed,
    Object? notes = freezed,
    Object? is_favorite = freezed,
    Object? is_saved = freezed,
    Object? is_formatted = freezed,
    Object? created_at = freezed,
    Object? created_by = freezed,
    Object? last_visited_at = freezed,
    Object? calories = freezed,
    Object? protein = freezed,
    Object? fat = freezed,
    Object? carbs = freezed,
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
      parent_id: freezed == parent_id
          ? _value.parent_id
          : parent_id // ignore: cast_nullable_to_non_nullable
              as int?,
      cooking_time: freezed == cooking_time
          ? _value.cooking_time
          : cooking_time // ignore: cast_nullable_to_non_nullable
              as int?,
      preparation_time: freezed == preparation_time
          ? _value.preparation_time
          : preparation_time // ignore: cast_nullable_to_non_nullable
              as int?,
      servings: freezed == servings
          ? _value.servings
          : servings // ignore: cast_nullable_to_non_nullable
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
      thumbnail_url: freezed == thumbnail_url
          ? _value.thumbnail_url
          : thumbnail_url // ignore: cast_nullable_to_non_nullable
              as String?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      is_favorite: freezed == is_favorite
          ? _value.is_favorite
          : is_favorite // ignore: cast_nullable_to_non_nullable
              as bool?,
      is_saved: freezed == is_saved
          ? _value.is_saved
          : is_saved // ignore: cast_nullable_to_non_nullable
              as bool?,
      is_formatted: freezed == is_formatted
          ? _value.is_formatted
          : is_formatted // ignore: cast_nullable_to_non_nullable
              as bool?,
      created_at: freezed == created_at
          ? _value.created_at
          : created_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      created_by: freezed == created_by
          ? _value.created_by
          : created_by // ignore: cast_nullable_to_non_nullable
              as User?,
      last_visited_at: freezed == last_visited_at
          ? _value.last_visited_at
          : last_visited_at // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      calories: freezed == calories
          ? _value.calories
          : calories // ignore: cast_nullable_to_non_nullable
              as double?,
      protein: freezed == protein
          ? _value.protein
          : protein // ignore: cast_nullable_to_non_nullable
              as double?,
      fat: freezed == fat
          ? _value.fat
          : fat // ignore: cast_nullable_to_non_nullable
              as double?,
      carbs: freezed == carbs
          ? _value.carbs
          : carbs // ignore: cast_nullable_to_non_nullable
              as double?,
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
      this.parent_id,
      this.cooking_time,
      this.preparation_time,
      this.servings,
      final List<String>? tags,
      this.description,
      this.image_url,
      this.thumbnail_url,
      this.notes,
      this.is_favorite,
      this.is_saved,
      this.is_formatted,
      this.created_at,
      this.created_by,
      this.last_visited_at,
      this.calories,
      this.protein,
      this.fat,
      this.carbs})
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
  final int? parent_id;
  @override
  final int? cooking_time;
  @override
  final int? preparation_time;
  @override
  final int? servings;
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
  final String? thumbnail_url;
  @override
  final String? notes;
  @override
  final bool? is_favorite;
  @override
  final bool? is_saved;
  @override
  final bool? is_formatted;
  @override
  final DateTime? created_at;
  @override
  final User? created_by;
  @override
  final DateTime? last_visited_at;
  @override
  final double? calories;
  @override
  final double? protein;
  @override
  final double? fat;
  @override
  final double? carbs;

  @override
  String toString() {
    return 'Recipe(id: $id, title: $title, ingredients: $ingredients, instructions: $instructions, parent_id: $parent_id, cooking_time: $cooking_time, preparation_time: $preparation_time, servings: $servings, tags: $tags, description: $description, image_url: $image_url, thumbnail_url: $thumbnail_url, notes: $notes, is_favorite: $is_favorite, is_saved: $is_saved, is_formatted: $is_formatted, created_at: $created_at, created_by: $created_by, last_visited_at: $last_visited_at, calories: $calories, protein: $protein, fat: $fat, carbs: $carbs)';
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
            (identical(other.parent_id, parent_id) ||
                other.parent_id == parent_id) &&
            (identical(other.cooking_time, cooking_time) ||
                other.cooking_time == cooking_time) &&
            (identical(other.preparation_time, preparation_time) ||
                other.preparation_time == preparation_time) &&
            (identical(other.servings, servings) ||
                other.servings == servings) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.image_url, image_url) ||
                other.image_url == image_url) &&
            (identical(other.thumbnail_url, thumbnail_url) ||
                other.thumbnail_url == thumbnail_url) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.is_favorite, is_favorite) ||
                other.is_favorite == is_favorite) &&
            (identical(other.is_saved, is_saved) ||
                other.is_saved == is_saved) &&
            (identical(other.is_formatted, is_formatted) ||
                other.is_formatted == is_formatted) &&
            (identical(other.created_at, created_at) ||
                other.created_at == created_at) &&
            (identical(other.created_by, created_by) ||
                other.created_by == created_by) &&
            (identical(other.last_visited_at, last_visited_at) ||
                other.last_visited_at == last_visited_at) &&
            (identical(other.calories, calories) ||
                other.calories == calories) &&
            (identical(other.protein, protein) || other.protein == protein) &&
            (identical(other.fat, fat) || other.fat == fat) &&
            (identical(other.carbs, carbs) || other.carbs == carbs));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hashAll([
        runtimeType,
        id,
        title,
        const DeepCollectionEquality().hash(_ingredients),
        const DeepCollectionEquality().hash(_instructions),
        parent_id,
        cooking_time,
        preparation_time,
        servings,
        const DeepCollectionEquality().hash(_tags),
        description,
        image_url,
        thumbnail_url,
        notes,
        is_favorite,
        is_saved,
        is_formatted,
        created_at,
        created_by,
        last_visited_at,
        calories,
        protein,
        fat,
        carbs
      ]);

  @JsonKey(ignore: true)
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
      final int? parent_id,
      final int? cooking_time,
      final int? preparation_time,
      final int? servings,
      final List<String>? tags,
      final String? description,
      final String? image_url,
      final String? thumbnail_url,
      final String? notes,
      final bool? is_favorite,
      final bool? is_saved,
      final bool? is_formatted,
      final DateTime? created_at,
      final User? created_by,
      final DateTime? last_visited_at,
      final double? calories,
      final double? protein,
      final double? fat,
      final double? carbs}) = _$RecipeImpl;

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
  int? get parent_id;
  @override
  int? get cooking_time;
  @override
  int? get preparation_time;
  @override
  int? get servings;
  @override
  List<String>? get tags;
  @override
  String? get description;
  @override
  String? get image_url;
  @override
  String? get thumbnail_url;
  @override
  String? get notes;
  @override
  bool? get is_favorite;
  @override
  bool? get is_saved;
  @override
  bool? get is_formatted;
  @override
  DateTime? get created_at;
  @override
  User? get created_by;
  @override
  DateTime? get last_visited_at;
  @override
  double? get calories;
  @override
  double? get protein;
  @override
  double? get fat;
  @override
  double? get carbs;
  @override
  @JsonKey(ignore: true)
  _$$RecipeImplCopyWith<_$RecipeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
