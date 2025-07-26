// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'paginated_recipes.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PaginatedRecipes _$PaginatedRecipesFromJson(Map<String, dynamic> json) {
  return _PaginatedRecipes.fromJson(json);
}

/// @nodoc
mixin _$PaginatedRecipes {
  int get count => throw _privateConstructorUsedError;
  List<RecipePreview> get results => throw _privateConstructorUsedError;
  String? get next => throw _privateConstructorUsedError;

  /// Serializes this PaginatedRecipes to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PaginatedRecipes
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PaginatedRecipesCopyWith<PaginatedRecipes> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaginatedRecipesCopyWith<$Res> {
  factory $PaginatedRecipesCopyWith(
          PaginatedRecipes value, $Res Function(PaginatedRecipes) then) =
      _$PaginatedRecipesCopyWithImpl<$Res, PaginatedRecipes>;
  @useResult
  $Res call({int count, List<RecipePreview> results, String? next});
}

/// @nodoc
class _$PaginatedRecipesCopyWithImpl<$Res, $Val extends PaginatedRecipes>
    implements $PaginatedRecipesCopyWith<$Res> {
  _$PaginatedRecipesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PaginatedRecipes
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? count = null,
    Object? results = null,
    Object? next = freezed,
  }) {
    return _then(_value.copyWith(
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      results: null == results
          ? _value.results
          : results // ignore: cast_nullable_to_non_nullable
              as List<RecipePreview>,
      next: freezed == next
          ? _value.next
          : next // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PaginatedRecipesImplCopyWith<$Res>
    implements $PaginatedRecipesCopyWith<$Res> {
  factory _$$PaginatedRecipesImplCopyWith(_$PaginatedRecipesImpl value,
          $Res Function(_$PaginatedRecipesImpl) then) =
      __$$PaginatedRecipesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int count, List<RecipePreview> results, String? next});
}

/// @nodoc
class __$$PaginatedRecipesImplCopyWithImpl<$Res>
    extends _$PaginatedRecipesCopyWithImpl<$Res, _$PaginatedRecipesImpl>
    implements _$$PaginatedRecipesImplCopyWith<$Res> {
  __$$PaginatedRecipesImplCopyWithImpl(_$PaginatedRecipesImpl _value,
      $Res Function(_$PaginatedRecipesImpl) _then)
      : super(_value, _then);

  /// Create a copy of PaginatedRecipes
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? count = null,
    Object? results = null,
    Object? next = freezed,
  }) {
    return _then(_$PaginatedRecipesImpl(
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      results: null == results
          ? _value._results
          : results // ignore: cast_nullable_to_non_nullable
              as List<RecipePreview>,
      next: freezed == next
          ? _value.next
          : next // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PaginatedRecipesImpl implements _PaginatedRecipes {
  const _$PaginatedRecipesImpl(
      {required this.count,
      required final List<RecipePreview> results,
      this.next})
      : _results = results;

  factory _$PaginatedRecipesImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaginatedRecipesImplFromJson(json);

  @override
  final int count;
  final List<RecipePreview> _results;
  @override
  List<RecipePreview> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @override
  final String? next;

  @override
  String toString() {
    return 'PaginatedRecipes(count: $count, results: $results, next: $next)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaginatedRecipesImpl &&
            (identical(other.count, count) || other.count == count) &&
            const DeepCollectionEquality().equals(other._results, _results) &&
            (identical(other.next, next) || other.next == next));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, count, const DeepCollectionEquality().hash(_results), next);

  /// Create a copy of PaginatedRecipes
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PaginatedRecipesImplCopyWith<_$PaginatedRecipesImpl> get copyWith =>
      __$$PaginatedRecipesImplCopyWithImpl<_$PaginatedRecipesImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PaginatedRecipesImplToJson(
      this,
    );
  }
}

abstract class _PaginatedRecipes implements PaginatedRecipes {
  const factory _PaginatedRecipes(
      {required final int count,
      required final List<RecipePreview> results,
      final String? next}) = _$PaginatedRecipesImpl;

  factory _PaginatedRecipes.fromJson(Map<String, dynamic> json) =
      _$PaginatedRecipesImpl.fromJson;

  @override
  int get count;
  @override
  List<RecipePreview> get results;
  @override
  String? get next;

  /// Create a copy of PaginatedRecipes
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PaginatedRecipesImplCopyWith<_$PaginatedRecipesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
