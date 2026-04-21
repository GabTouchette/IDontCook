// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ingredient.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Ingredient _$IngredientFromJson(Map<String, dynamic> json) {
  return _Ingredient.fromJson(json);
}

/// @nodoc
mixin _$Ingredient {
  int? get id => throw _privateConstructorUsedError;
  String? get name => throw _privateConstructorUsedError;
  double? get quantity => throw _privateConstructorUsedError;
  String? get unit => throw _privateConstructorUsedError;
  List<String>? get substitutes => throw _privateConstructorUsedError;
  Map<String, dynamic>? get nutrition => throw _privateConstructorUsedError;
  int? get canonical => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $IngredientCopyWith<Ingredient> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $IngredientCopyWith<$Res> {
  factory $IngredientCopyWith(
          Ingredient value, $Res Function(Ingredient) then) =
      _$IngredientCopyWithImpl<$Res, Ingredient>;
  @useResult
  $Res call(
      {int? id,
      String? name,
      double? quantity,
      String? unit,
      List<String>? substitutes,
      Map<String, dynamic>? nutrition,
      int? canonical});
}

/// @nodoc
class _$IngredientCopyWithImpl<$Res, $Val extends Ingredient>
    implements $IngredientCopyWith<$Res> {
  _$IngredientCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = freezed,
    Object? quantity = freezed,
    Object? unit = freezed,
    Object? substitutes = freezed,
    Object? nutrition = freezed,
    Object? canonical = freezed,
  }) {
    return _then(_value.copyWith(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: freezed == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double?,
      unit: freezed == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
      substitutes: freezed == substitutes
          ? _value.substitutes
          : substitutes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      nutrition: freezed == nutrition
          ? _value.nutrition
          : nutrition // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      canonical: freezed == canonical
          ? _value.canonical
          : canonical // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$IngredientImplCopyWith<$Res>
    implements $IngredientCopyWith<$Res> {
  factory _$$IngredientImplCopyWith(
          _$IngredientImpl value, $Res Function(_$IngredientImpl) then) =
      __$$IngredientImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int? id,
      String? name,
      double? quantity,
      String? unit,
      List<String>? substitutes,
      Map<String, dynamic>? nutrition,
      int? canonical});
}

/// @nodoc
class __$$IngredientImplCopyWithImpl<$Res>
    extends _$IngredientCopyWithImpl<$Res, _$IngredientImpl>
    implements _$$IngredientImplCopyWith<$Res> {
  __$$IngredientImplCopyWithImpl(
      _$IngredientImpl _value, $Res Function(_$IngredientImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? name = freezed,
    Object? quantity = freezed,
    Object? unit = freezed,
    Object? substitutes = freezed,
    Object? nutrition = freezed,
    Object? canonical = freezed,
  }) {
    return _then(_$IngredientImpl(
      id: freezed == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      name: freezed == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      quantity: freezed == quantity
          ? _value.quantity
          : quantity // ignore: cast_nullable_to_non_nullable
              as double?,
      unit: freezed == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
      substitutes: freezed == substitutes
          ? _value._substitutes
          : substitutes // ignore: cast_nullable_to_non_nullable
              as List<String>?,
      nutrition: freezed == nutrition
          ? _value._nutrition
          : nutrition // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>?,
      canonical: freezed == canonical
          ? _value.canonical
          : canonical // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$IngredientImpl implements _Ingredient {
  const _$IngredientImpl(
      {this.id,
      this.name,
      this.quantity,
      this.unit,
      final List<String>? substitutes,
      final Map<String, dynamic>? nutrition,
      this.canonical})
      : _substitutes = substitutes,
        _nutrition = nutrition;

  factory _$IngredientImpl.fromJson(Map<String, dynamic> json) =>
      _$$IngredientImplFromJson(json);

  @override
  final int? id;
  @override
  final String? name;
  @override
  final double? quantity;
  @override
  final String? unit;
  final List<String>? _substitutes;
  @override
  List<String>? get substitutes {
    final value = _substitutes;
    if (value == null) return null;
    if (_substitutes is EqualUnmodifiableListView) return _substitutes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(value);
  }

  final Map<String, dynamic>? _nutrition;
  @override
  Map<String, dynamic>? get nutrition {
    final value = _nutrition;
    if (value == null) return null;
    if (_nutrition is EqualUnmodifiableMapView) return _nutrition;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(value);
  }

  @override
  final int? canonical;

  @override
  String toString() {
    return 'Ingredient(id: $id, name: $name, quantity: $quantity, unit: $unit, substitutes: $substitutes, nutrition: $nutrition, canonical: $canonical)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$IngredientImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            const DeepCollectionEquality()
                .equals(other._substitutes, _substitutes) &&
            const DeepCollectionEquality()
                .equals(other._nutrition, _nutrition) &&
            (identical(other.canonical, canonical) ||
                other.canonical == canonical));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      quantity,
      unit,
      const DeepCollectionEquality().hash(_substitutes),
      const DeepCollectionEquality().hash(_nutrition),
      canonical);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$IngredientImplCopyWith<_$IngredientImpl> get copyWith =>
      __$$IngredientImplCopyWithImpl<_$IngredientImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$IngredientImplToJson(
      this,
    );
  }
}

abstract class _Ingredient implements Ingredient {
  const factory _Ingredient(
      {final int? id,
      final String? name,
      final double? quantity,
      final String? unit,
      final List<String>? substitutes,
      final Map<String, dynamic>? nutrition,
      final int? canonical}) = _$IngredientImpl;

  factory _Ingredient.fromJson(Map<String, dynamic> json) =
      _$IngredientImpl.fromJson;

  @override
  int? get id;
  @override
  String? get name;
  @override
  double? get quantity;
  @override
  String? get unit;
  @override
  List<String>? get substitutes;
  @override
  Map<String, dynamic>? get nutrition;
  @override
  int? get canonical;
  @override
  @JsonKey(ignore: true)
  _$$IngredientImplCopyWith<_$IngredientImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
