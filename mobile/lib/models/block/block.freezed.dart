// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'block.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Block _$BlockFromJson(Map<String, dynamic> json) {
  switch (json['block_type']) {
    case 'text':
      return TextBlock.fromJson(json);
    case 'recipe':
      return RecipeBlock.fromJson(json);
    case 'recipe_ref':
      return RecipeRefBlock.fromJson(json);
    case 'recipe_update':
      return RecipeUpdateBlock.fromJson(json);
    case 'module':
      return ModuleBlock.fromJson(json);

    default:
      return UnknownBlock.fromJson(json);
  }
}

/// @nodoc
mixin _$Block {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String text) text,
    required TResult Function(Recipe recipe) recipe,
    required TResult Function(RecipeSummary recipe) recipeRef,
    required TResult Function(int recipe_id, Map<String, dynamic> changes)
        recipeUpdate,
    required TResult Function(HomeModule module) module,
    required TResult Function() unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String text)? text,
    TResult? Function(Recipe recipe)? recipe,
    TResult? Function(RecipeSummary recipe)? recipeRef,
    TResult? Function(int recipe_id, Map<String, dynamic> changes)?
        recipeUpdate,
    TResult? Function(HomeModule module)? module,
    TResult? Function()? unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String text)? text,
    TResult Function(Recipe recipe)? recipe,
    TResult Function(RecipeSummary recipe)? recipeRef,
    TResult Function(int recipe_id, Map<String, dynamic> changes)? recipeUpdate,
    TResult Function(HomeModule module)? module,
    TResult Function()? unknown,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextBlock value) text,
    required TResult Function(RecipeBlock value) recipe,
    required TResult Function(RecipeRefBlock value) recipeRef,
    required TResult Function(RecipeUpdateBlock value) recipeUpdate,
    required TResult Function(ModuleBlock value) module,
    required TResult Function(UnknownBlock value) unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextBlock value)? text,
    TResult? Function(RecipeBlock value)? recipe,
    TResult? Function(RecipeRefBlock value)? recipeRef,
    TResult? Function(RecipeUpdateBlock value)? recipeUpdate,
    TResult? Function(ModuleBlock value)? module,
    TResult? Function(UnknownBlock value)? unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextBlock value)? text,
    TResult Function(RecipeBlock value)? recipe,
    TResult Function(RecipeRefBlock value)? recipeRef,
    TResult Function(RecipeUpdateBlock value)? recipeUpdate,
    TResult Function(ModuleBlock value)? module,
    TResult Function(UnknownBlock value)? unknown,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BlockCopyWith<$Res> {
  factory $BlockCopyWith(Block value, $Res Function(Block) then) =
      _$BlockCopyWithImpl<$Res, Block>;
}

/// @nodoc
class _$BlockCopyWithImpl<$Res, $Val extends Block>
    implements $BlockCopyWith<$Res> {
  _$BlockCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$TextBlockImplCopyWith<$Res> {
  factory _$$TextBlockImplCopyWith(
          _$TextBlockImpl value, $Res Function(_$TextBlockImpl) then) =
      __$$TextBlockImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String text});
}

/// @nodoc
class __$$TextBlockImplCopyWithImpl<$Res>
    extends _$BlockCopyWithImpl<$Res, _$TextBlockImpl>
    implements _$$TextBlockImplCopyWith<$Res> {
  __$$TextBlockImplCopyWithImpl(
      _$TextBlockImpl _value, $Res Function(_$TextBlockImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
  }) {
    return _then(_$TextBlockImpl(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TextBlockImpl implements TextBlock {
  const _$TextBlockImpl({this.text = '', final String? $type})
      : $type = $type ?? 'text';

  factory _$TextBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$TextBlockImplFromJson(json);

  @override
  @JsonKey()
  final String text;

  @JsonKey(name: 'block_type')
  final String $type;

  @override
  String toString() {
    return 'Block.text(text: $text)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TextBlockImpl &&
            (identical(other.text, text) || other.text == text));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, text);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TextBlockImplCopyWith<_$TextBlockImpl> get copyWith =>
      __$$TextBlockImplCopyWithImpl<_$TextBlockImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String text) text,
    required TResult Function(Recipe recipe) recipe,
    required TResult Function(RecipeSummary recipe) recipeRef,
    required TResult Function(int recipe_id, Map<String, dynamic> changes)
        recipeUpdate,
    required TResult Function(HomeModule module) module,
    required TResult Function() unknown,
  }) {
    return text(this.text);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String text)? text,
    TResult? Function(Recipe recipe)? recipe,
    TResult? Function(RecipeSummary recipe)? recipeRef,
    TResult? Function(int recipe_id, Map<String, dynamic> changes)?
        recipeUpdate,
    TResult? Function(HomeModule module)? module,
    TResult? Function()? unknown,
  }) {
    return text?.call(this.text);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String text)? text,
    TResult Function(Recipe recipe)? recipe,
    TResult Function(RecipeSummary recipe)? recipeRef,
    TResult Function(int recipe_id, Map<String, dynamic> changes)? recipeUpdate,
    TResult Function(HomeModule module)? module,
    TResult Function()? unknown,
    required TResult orElse(),
  }) {
    if (text != null) {
      return text(this.text);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextBlock value) text,
    required TResult Function(RecipeBlock value) recipe,
    required TResult Function(RecipeRefBlock value) recipeRef,
    required TResult Function(RecipeUpdateBlock value) recipeUpdate,
    required TResult Function(ModuleBlock value) module,
    required TResult Function(UnknownBlock value) unknown,
  }) {
    return text(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextBlock value)? text,
    TResult? Function(RecipeBlock value)? recipe,
    TResult? Function(RecipeRefBlock value)? recipeRef,
    TResult? Function(RecipeUpdateBlock value)? recipeUpdate,
    TResult? Function(ModuleBlock value)? module,
    TResult? Function(UnknownBlock value)? unknown,
  }) {
    return text?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextBlock value)? text,
    TResult Function(RecipeBlock value)? recipe,
    TResult Function(RecipeRefBlock value)? recipeRef,
    TResult Function(RecipeUpdateBlock value)? recipeUpdate,
    TResult Function(ModuleBlock value)? module,
    TResult Function(UnknownBlock value)? unknown,
    required TResult orElse(),
  }) {
    if (text != null) {
      return text(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$TextBlockImplToJson(
      this,
    );
  }
}

abstract class TextBlock implements Block {
  const factory TextBlock({final String text}) = _$TextBlockImpl;

  factory TextBlock.fromJson(Map<String, dynamic> json) =
      _$TextBlockImpl.fromJson;

  String get text;
  @JsonKey(ignore: true)
  _$$TextBlockImplCopyWith<_$TextBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RecipeBlockImplCopyWith<$Res> {
  factory _$$RecipeBlockImplCopyWith(
          _$RecipeBlockImpl value, $Res Function(_$RecipeBlockImpl) then) =
      __$$RecipeBlockImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Recipe recipe});

  $RecipeCopyWith<$Res> get recipe;
}

/// @nodoc
class __$$RecipeBlockImplCopyWithImpl<$Res>
    extends _$BlockCopyWithImpl<$Res, _$RecipeBlockImpl>
    implements _$$RecipeBlockImplCopyWith<$Res> {
  __$$RecipeBlockImplCopyWithImpl(
      _$RecipeBlockImpl _value, $Res Function(_$RecipeBlockImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recipe = null,
  }) {
    return _then(_$RecipeBlockImpl(
      recipe: null == recipe
          ? _value.recipe
          : recipe // ignore: cast_nullable_to_non_nullable
              as Recipe,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $RecipeCopyWith<$Res> get recipe {
    return $RecipeCopyWith<$Res>(_value.recipe, (value) {
      return _then(_value.copyWith(recipe: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$RecipeBlockImpl implements RecipeBlock {
  const _$RecipeBlockImpl({required this.recipe, final String? $type})
      : $type = $type ?? 'recipe';

  factory _$RecipeBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipeBlockImplFromJson(json);

  @override
  final Recipe recipe;

  @JsonKey(name: 'block_type')
  final String $type;

  @override
  String toString() {
    return 'Block.recipe(recipe: $recipe)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipeBlockImpl &&
            (identical(other.recipe, recipe) || other.recipe == recipe));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, recipe);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipeBlockImplCopyWith<_$RecipeBlockImpl> get copyWith =>
      __$$RecipeBlockImplCopyWithImpl<_$RecipeBlockImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String text) text,
    required TResult Function(Recipe recipe) recipe,
    required TResult Function(RecipeSummary recipe) recipeRef,
    required TResult Function(int recipe_id, Map<String, dynamic> changes)
        recipeUpdate,
    required TResult Function(HomeModule module) module,
    required TResult Function() unknown,
  }) {
    return recipe(this.recipe);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String text)? text,
    TResult? Function(Recipe recipe)? recipe,
    TResult? Function(RecipeSummary recipe)? recipeRef,
    TResult? Function(int recipe_id, Map<String, dynamic> changes)?
        recipeUpdate,
    TResult? Function(HomeModule module)? module,
    TResult? Function()? unknown,
  }) {
    return recipe?.call(this.recipe);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String text)? text,
    TResult Function(Recipe recipe)? recipe,
    TResult Function(RecipeSummary recipe)? recipeRef,
    TResult Function(int recipe_id, Map<String, dynamic> changes)? recipeUpdate,
    TResult Function(HomeModule module)? module,
    TResult Function()? unknown,
    required TResult orElse(),
  }) {
    if (recipe != null) {
      return recipe(this.recipe);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextBlock value) text,
    required TResult Function(RecipeBlock value) recipe,
    required TResult Function(RecipeRefBlock value) recipeRef,
    required TResult Function(RecipeUpdateBlock value) recipeUpdate,
    required TResult Function(ModuleBlock value) module,
    required TResult Function(UnknownBlock value) unknown,
  }) {
    return recipe(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextBlock value)? text,
    TResult? Function(RecipeBlock value)? recipe,
    TResult? Function(RecipeRefBlock value)? recipeRef,
    TResult? Function(RecipeUpdateBlock value)? recipeUpdate,
    TResult? Function(ModuleBlock value)? module,
    TResult? Function(UnknownBlock value)? unknown,
  }) {
    return recipe?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextBlock value)? text,
    TResult Function(RecipeBlock value)? recipe,
    TResult Function(RecipeRefBlock value)? recipeRef,
    TResult Function(RecipeUpdateBlock value)? recipeUpdate,
    TResult Function(ModuleBlock value)? module,
    TResult Function(UnknownBlock value)? unknown,
    required TResult orElse(),
  }) {
    if (recipe != null) {
      return recipe(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$RecipeBlockImplToJson(
      this,
    );
  }
}

abstract class RecipeBlock implements Block {
  const factory RecipeBlock({required final Recipe recipe}) = _$RecipeBlockImpl;

  factory RecipeBlock.fromJson(Map<String, dynamic> json) =
      _$RecipeBlockImpl.fromJson;

  Recipe get recipe;
  @JsonKey(ignore: true)
  _$$RecipeBlockImplCopyWith<_$RecipeBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RecipeRefBlockImplCopyWith<$Res> {
  factory _$$RecipeRefBlockImplCopyWith(_$RecipeRefBlockImpl value,
          $Res Function(_$RecipeRefBlockImpl) then) =
      __$$RecipeRefBlockImplCopyWithImpl<$Res>;
  @useResult
  $Res call({RecipeSummary recipe});

  $RecipeSummaryCopyWith<$Res> get recipe;
}

/// @nodoc
class __$$RecipeRefBlockImplCopyWithImpl<$Res>
    extends _$BlockCopyWithImpl<$Res, _$RecipeRefBlockImpl>
    implements _$$RecipeRefBlockImplCopyWith<$Res> {
  __$$RecipeRefBlockImplCopyWithImpl(
      _$RecipeRefBlockImpl _value, $Res Function(_$RecipeRefBlockImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recipe = null,
  }) {
    return _then(_$RecipeRefBlockImpl(
      recipe: null == recipe
          ? _value.recipe
          : recipe // ignore: cast_nullable_to_non_nullable
              as RecipeSummary,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $RecipeSummaryCopyWith<$Res> get recipe {
    return $RecipeSummaryCopyWith<$Res>(_value.recipe, (value) {
      return _then(_value.copyWith(recipe: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$RecipeRefBlockImpl implements RecipeRefBlock {
  const _$RecipeRefBlockImpl({required this.recipe, final String? $type})
      : $type = $type ?? 'recipe_ref';

  factory _$RecipeRefBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipeRefBlockImplFromJson(json);

  @override
  final RecipeSummary recipe;

  @JsonKey(name: 'block_type')
  final String $type;

  @override
  String toString() {
    return 'Block.recipeRef(recipe: $recipe)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipeRefBlockImpl &&
            (identical(other.recipe, recipe) || other.recipe == recipe));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, recipe);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipeRefBlockImplCopyWith<_$RecipeRefBlockImpl> get copyWith =>
      __$$RecipeRefBlockImplCopyWithImpl<_$RecipeRefBlockImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String text) text,
    required TResult Function(Recipe recipe) recipe,
    required TResult Function(RecipeSummary recipe) recipeRef,
    required TResult Function(int recipe_id, Map<String, dynamic> changes)
        recipeUpdate,
    required TResult Function(HomeModule module) module,
    required TResult Function() unknown,
  }) {
    return recipeRef(this.recipe);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String text)? text,
    TResult? Function(Recipe recipe)? recipe,
    TResult? Function(RecipeSummary recipe)? recipeRef,
    TResult? Function(int recipe_id, Map<String, dynamic> changes)?
        recipeUpdate,
    TResult? Function(HomeModule module)? module,
    TResult? Function()? unknown,
  }) {
    return recipeRef?.call(this.recipe);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String text)? text,
    TResult Function(Recipe recipe)? recipe,
    TResult Function(RecipeSummary recipe)? recipeRef,
    TResult Function(int recipe_id, Map<String, dynamic> changes)? recipeUpdate,
    TResult Function(HomeModule module)? module,
    TResult Function()? unknown,
    required TResult orElse(),
  }) {
    if (recipeRef != null) {
      return recipeRef(this.recipe);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextBlock value) text,
    required TResult Function(RecipeBlock value) recipe,
    required TResult Function(RecipeRefBlock value) recipeRef,
    required TResult Function(RecipeUpdateBlock value) recipeUpdate,
    required TResult Function(ModuleBlock value) module,
    required TResult Function(UnknownBlock value) unknown,
  }) {
    return recipeRef(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextBlock value)? text,
    TResult? Function(RecipeBlock value)? recipe,
    TResult? Function(RecipeRefBlock value)? recipeRef,
    TResult? Function(RecipeUpdateBlock value)? recipeUpdate,
    TResult? Function(ModuleBlock value)? module,
    TResult? Function(UnknownBlock value)? unknown,
  }) {
    return recipeRef?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextBlock value)? text,
    TResult Function(RecipeBlock value)? recipe,
    TResult Function(RecipeRefBlock value)? recipeRef,
    TResult Function(RecipeUpdateBlock value)? recipeUpdate,
    TResult Function(ModuleBlock value)? module,
    TResult Function(UnknownBlock value)? unknown,
    required TResult orElse(),
  }) {
    if (recipeRef != null) {
      return recipeRef(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$RecipeRefBlockImplToJson(
      this,
    );
  }
}

abstract class RecipeRefBlock implements Block {
  const factory RecipeRefBlock({required final RecipeSummary recipe}) =
      _$RecipeRefBlockImpl;

  factory RecipeRefBlock.fromJson(Map<String, dynamic> json) =
      _$RecipeRefBlockImpl.fromJson;

  RecipeSummary get recipe;
  @JsonKey(ignore: true)
  _$$RecipeRefBlockImplCopyWith<_$RecipeRefBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$RecipeUpdateBlockImplCopyWith<$Res> {
  factory _$$RecipeUpdateBlockImplCopyWith(_$RecipeUpdateBlockImpl value,
          $Res Function(_$RecipeUpdateBlockImpl) then) =
      __$$RecipeUpdateBlockImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int recipe_id, Map<String, dynamic> changes});
}

/// @nodoc
class __$$RecipeUpdateBlockImplCopyWithImpl<$Res>
    extends _$BlockCopyWithImpl<$Res, _$RecipeUpdateBlockImpl>
    implements _$$RecipeUpdateBlockImplCopyWith<$Res> {
  __$$RecipeUpdateBlockImplCopyWithImpl(_$RecipeUpdateBlockImpl _value,
      $Res Function(_$RecipeUpdateBlockImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? recipe_id = null,
    Object? changes = null,
  }) {
    return _then(_$RecipeUpdateBlockImpl(
      recipe_id: null == recipe_id
          ? _value.recipe_id
          : recipe_id // ignore: cast_nullable_to_non_nullable
              as int,
      changes: null == changes
          ? _value._changes
          : changes // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecipeUpdateBlockImpl implements RecipeUpdateBlock {
  const _$RecipeUpdateBlockImpl(
      {required this.recipe_id,
      final Map<String, dynamic> changes = const <String, dynamic>{},
      final String? $type})
      : _changes = changes,
        $type = $type ?? 'recipe_update';

  factory _$RecipeUpdateBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipeUpdateBlockImplFromJson(json);

  @override
  final int recipe_id;
  final Map<String, dynamic> _changes;
  @override
  @JsonKey()
  Map<String, dynamic> get changes {
    if (_changes is EqualUnmodifiableMapView) return _changes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_changes);
  }

  @JsonKey(name: 'block_type')
  final String $type;

  @override
  String toString() {
    return 'Block.recipeUpdate(recipe_id: $recipe_id, changes: $changes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipeUpdateBlockImpl &&
            (identical(other.recipe_id, recipe_id) ||
                other.recipe_id == recipe_id) &&
            const DeepCollectionEquality().equals(other._changes, _changes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, recipe_id, const DeepCollectionEquality().hash(_changes));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipeUpdateBlockImplCopyWith<_$RecipeUpdateBlockImpl> get copyWith =>
      __$$RecipeUpdateBlockImplCopyWithImpl<_$RecipeUpdateBlockImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String text) text,
    required TResult Function(Recipe recipe) recipe,
    required TResult Function(RecipeSummary recipe) recipeRef,
    required TResult Function(int recipe_id, Map<String, dynamic> changes)
        recipeUpdate,
    required TResult Function(HomeModule module) module,
    required TResult Function() unknown,
  }) {
    return recipeUpdate(recipe_id, changes);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String text)? text,
    TResult? Function(Recipe recipe)? recipe,
    TResult? Function(RecipeSummary recipe)? recipeRef,
    TResult? Function(int recipe_id, Map<String, dynamic> changes)?
        recipeUpdate,
    TResult? Function(HomeModule module)? module,
    TResult? Function()? unknown,
  }) {
    return recipeUpdate?.call(recipe_id, changes);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String text)? text,
    TResult Function(Recipe recipe)? recipe,
    TResult Function(RecipeSummary recipe)? recipeRef,
    TResult Function(int recipe_id, Map<String, dynamic> changes)? recipeUpdate,
    TResult Function(HomeModule module)? module,
    TResult Function()? unknown,
    required TResult orElse(),
  }) {
    if (recipeUpdate != null) {
      return recipeUpdate(recipe_id, changes);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextBlock value) text,
    required TResult Function(RecipeBlock value) recipe,
    required TResult Function(RecipeRefBlock value) recipeRef,
    required TResult Function(RecipeUpdateBlock value) recipeUpdate,
    required TResult Function(ModuleBlock value) module,
    required TResult Function(UnknownBlock value) unknown,
  }) {
    return recipeUpdate(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextBlock value)? text,
    TResult? Function(RecipeBlock value)? recipe,
    TResult? Function(RecipeRefBlock value)? recipeRef,
    TResult? Function(RecipeUpdateBlock value)? recipeUpdate,
    TResult? Function(ModuleBlock value)? module,
    TResult? Function(UnknownBlock value)? unknown,
  }) {
    return recipeUpdate?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextBlock value)? text,
    TResult Function(RecipeBlock value)? recipe,
    TResult Function(RecipeRefBlock value)? recipeRef,
    TResult Function(RecipeUpdateBlock value)? recipeUpdate,
    TResult Function(ModuleBlock value)? module,
    TResult Function(UnknownBlock value)? unknown,
    required TResult orElse(),
  }) {
    if (recipeUpdate != null) {
      return recipeUpdate(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$RecipeUpdateBlockImplToJson(
      this,
    );
  }
}

abstract class RecipeUpdateBlock implements Block {
  const factory RecipeUpdateBlock(
      {required final int recipe_id,
      final Map<String, dynamic> changes}) = _$RecipeUpdateBlockImpl;

  factory RecipeUpdateBlock.fromJson(Map<String, dynamic> json) =
      _$RecipeUpdateBlockImpl.fromJson;

  int get recipe_id;
  Map<String, dynamic> get changes;
  @JsonKey(ignore: true)
  _$$RecipeUpdateBlockImplCopyWith<_$RecipeUpdateBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ModuleBlockImplCopyWith<$Res> {
  factory _$$ModuleBlockImplCopyWith(
          _$ModuleBlockImpl value, $Res Function(_$ModuleBlockImpl) then) =
      __$$ModuleBlockImplCopyWithImpl<$Res>;
  @useResult
  $Res call({HomeModule module});

  $HomeModuleCopyWith<$Res> get module;
}

/// @nodoc
class __$$ModuleBlockImplCopyWithImpl<$Res>
    extends _$BlockCopyWithImpl<$Res, _$ModuleBlockImpl>
    implements _$$ModuleBlockImplCopyWith<$Res> {
  __$$ModuleBlockImplCopyWithImpl(
      _$ModuleBlockImpl _value, $Res Function(_$ModuleBlockImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? module = null,
  }) {
    return _then(_$ModuleBlockImpl(
      module: null == module
          ? _value.module
          : module // ignore: cast_nullable_to_non_nullable
              as HomeModule,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $HomeModuleCopyWith<$Res> get module {
    return $HomeModuleCopyWith<$Res>(_value.module, (value) {
      return _then(_value.copyWith(module: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$ModuleBlockImpl implements ModuleBlock {
  const _$ModuleBlockImpl({required this.module, final String? $type})
      : $type = $type ?? 'module';

  factory _$ModuleBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$ModuleBlockImplFromJson(json);

  @override
  final HomeModule module;

  @JsonKey(name: 'block_type')
  final String $type;

  @override
  String toString() {
    return 'Block.module(module: $module)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ModuleBlockImpl &&
            (identical(other.module, module) || other.module == module));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, module);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ModuleBlockImplCopyWith<_$ModuleBlockImpl> get copyWith =>
      __$$ModuleBlockImplCopyWithImpl<_$ModuleBlockImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String text) text,
    required TResult Function(Recipe recipe) recipe,
    required TResult Function(RecipeSummary recipe) recipeRef,
    required TResult Function(int recipe_id, Map<String, dynamic> changes)
        recipeUpdate,
    required TResult Function(HomeModule module) module,
    required TResult Function() unknown,
  }) {
    return module(this.module);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String text)? text,
    TResult? Function(Recipe recipe)? recipe,
    TResult? Function(RecipeSummary recipe)? recipeRef,
    TResult? Function(int recipe_id, Map<String, dynamic> changes)?
        recipeUpdate,
    TResult? Function(HomeModule module)? module,
    TResult? Function()? unknown,
  }) {
    return module?.call(this.module);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String text)? text,
    TResult Function(Recipe recipe)? recipe,
    TResult Function(RecipeSummary recipe)? recipeRef,
    TResult Function(int recipe_id, Map<String, dynamic> changes)? recipeUpdate,
    TResult Function(HomeModule module)? module,
    TResult Function()? unknown,
    required TResult orElse(),
  }) {
    if (module != null) {
      return module(this.module);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextBlock value) text,
    required TResult Function(RecipeBlock value) recipe,
    required TResult Function(RecipeRefBlock value) recipeRef,
    required TResult Function(RecipeUpdateBlock value) recipeUpdate,
    required TResult Function(ModuleBlock value) module,
    required TResult Function(UnknownBlock value) unknown,
  }) {
    return module(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextBlock value)? text,
    TResult? Function(RecipeBlock value)? recipe,
    TResult? Function(RecipeRefBlock value)? recipeRef,
    TResult? Function(RecipeUpdateBlock value)? recipeUpdate,
    TResult? Function(ModuleBlock value)? module,
    TResult? Function(UnknownBlock value)? unknown,
  }) {
    return module?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextBlock value)? text,
    TResult Function(RecipeBlock value)? recipe,
    TResult Function(RecipeRefBlock value)? recipeRef,
    TResult Function(RecipeUpdateBlock value)? recipeUpdate,
    TResult Function(ModuleBlock value)? module,
    TResult Function(UnknownBlock value)? unknown,
    required TResult orElse(),
  }) {
    if (module != null) {
      return module(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ModuleBlockImplToJson(
      this,
    );
  }
}

abstract class ModuleBlock implements Block {
  const factory ModuleBlock({required final HomeModule module}) =
      _$ModuleBlockImpl;

  factory ModuleBlock.fromJson(Map<String, dynamic> json) =
      _$ModuleBlockImpl.fromJson;

  HomeModule get module;
  @JsonKey(ignore: true)
  _$$ModuleBlockImplCopyWith<_$ModuleBlockImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$UnknownBlockImplCopyWith<$Res> {
  factory _$$UnknownBlockImplCopyWith(
          _$UnknownBlockImpl value, $Res Function(_$UnknownBlockImpl) then) =
      __$$UnknownBlockImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$UnknownBlockImplCopyWithImpl<$Res>
    extends _$BlockCopyWithImpl<$Res, _$UnknownBlockImpl>
    implements _$$UnknownBlockImplCopyWith<$Res> {
  __$$UnknownBlockImplCopyWithImpl(
      _$UnknownBlockImpl _value, $Res Function(_$UnknownBlockImpl) _then)
      : super(_value, _then);
}

/// @nodoc
@JsonSerializable()
class _$UnknownBlockImpl implements UnknownBlock {
  const _$UnknownBlockImpl({final String? $type}) : $type = $type ?? 'unknown';

  factory _$UnknownBlockImpl.fromJson(Map<String, dynamic> json) =>
      _$$UnknownBlockImplFromJson(json);

  @JsonKey(name: 'block_type')
  final String $type;

  @override
  String toString() {
    return 'Block.unknown()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$UnknownBlockImpl);
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(String text) text,
    required TResult Function(Recipe recipe) recipe,
    required TResult Function(RecipeSummary recipe) recipeRef,
    required TResult Function(int recipe_id, Map<String, dynamic> changes)
        recipeUpdate,
    required TResult Function(HomeModule module) module,
    required TResult Function() unknown,
  }) {
    return unknown();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(String text)? text,
    TResult? Function(Recipe recipe)? recipe,
    TResult? Function(RecipeSummary recipe)? recipeRef,
    TResult? Function(int recipe_id, Map<String, dynamic> changes)?
        recipeUpdate,
    TResult? Function(HomeModule module)? module,
    TResult? Function()? unknown,
  }) {
    return unknown?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(String text)? text,
    TResult Function(Recipe recipe)? recipe,
    TResult Function(RecipeSummary recipe)? recipeRef,
    TResult Function(int recipe_id, Map<String, dynamic> changes)? recipeUpdate,
    TResult Function(HomeModule module)? module,
    TResult Function()? unknown,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(TextBlock value) text,
    required TResult Function(RecipeBlock value) recipe,
    required TResult Function(RecipeRefBlock value) recipeRef,
    required TResult Function(RecipeUpdateBlock value) recipeUpdate,
    required TResult Function(ModuleBlock value) module,
    required TResult Function(UnknownBlock value) unknown,
  }) {
    return unknown(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(TextBlock value)? text,
    TResult? Function(RecipeBlock value)? recipe,
    TResult? Function(RecipeRefBlock value)? recipeRef,
    TResult? Function(RecipeUpdateBlock value)? recipeUpdate,
    TResult? Function(ModuleBlock value)? module,
    TResult? Function(UnknownBlock value)? unknown,
  }) {
    return unknown?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(TextBlock value)? text,
    TResult Function(RecipeBlock value)? recipe,
    TResult Function(RecipeRefBlock value)? recipeRef,
    TResult Function(RecipeUpdateBlock value)? recipeUpdate,
    TResult Function(ModuleBlock value)? module,
    TResult Function(UnknownBlock value)? unknown,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$UnknownBlockImplToJson(
      this,
    );
  }
}

abstract class UnknownBlock implements Block {
  const factory UnknownBlock() = _$UnknownBlockImpl;

  factory UnknownBlock.fromJson(Map<String, dynamic> json) =
      _$UnknownBlockImpl.fromJson;
}
