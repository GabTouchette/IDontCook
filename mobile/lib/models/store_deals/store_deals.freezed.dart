// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'store_deals.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

StoreDeals _$StoreDealsFromJson(Map<String, dynamic> json) {
  return _StoreDeals.fromJson(json);
}

/// @nodoc
mixin _$StoreDeals {
  String? get postal_code => throw _privateConstructorUsedError;
  List<DealStore> get stores => throw _privateConstructorUsedError;
  int get total_count => throw _privateConstructorUsedError;
  List<DealItem> get items => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $StoreDealsCopyWith<StoreDeals> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $StoreDealsCopyWith<$Res> {
  factory $StoreDealsCopyWith(
          StoreDeals value, $Res Function(StoreDeals) then) =
      _$StoreDealsCopyWithImpl<$Res, StoreDeals>;
  @useResult
  $Res call(
      {String? postal_code,
      List<DealStore> stores,
      int total_count,
      List<DealItem> items});
}

/// @nodoc
class _$StoreDealsCopyWithImpl<$Res, $Val extends StoreDeals>
    implements $StoreDealsCopyWith<$Res> {
  _$StoreDealsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? postal_code = freezed,
    Object? stores = null,
    Object? total_count = null,
    Object? items = null,
  }) {
    return _then(_value.copyWith(
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
abstract class _$$StoreDealsImplCopyWith<$Res>
    implements $StoreDealsCopyWith<$Res> {
  factory _$$StoreDealsImplCopyWith(
          _$StoreDealsImpl value, $Res Function(_$StoreDealsImpl) then) =
      __$$StoreDealsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String? postal_code,
      List<DealStore> stores,
      int total_count,
      List<DealItem> items});
}

/// @nodoc
class __$$StoreDealsImplCopyWithImpl<$Res>
    extends _$StoreDealsCopyWithImpl<$Res, _$StoreDealsImpl>
    implements _$$StoreDealsImplCopyWith<$Res> {
  __$$StoreDealsImplCopyWithImpl(
      _$StoreDealsImpl _value, $Res Function(_$StoreDealsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? postal_code = freezed,
    Object? stores = null,
    Object? total_count = null,
    Object? items = null,
  }) {
    return _then(_$StoreDealsImpl(
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
class _$StoreDealsImpl implements _StoreDeals {
  const _$StoreDealsImpl(
      {this.postal_code,
      final List<DealStore> stores = const <DealStore>[],
      this.total_count = 0,
      final List<DealItem> items = const <DealItem>[]})
      : _stores = stores,
        _items = items;

  factory _$StoreDealsImpl.fromJson(Map<String, dynamic> json) =>
      _$$StoreDealsImplFromJson(json);

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
    return 'StoreDeals(postal_code: $postal_code, stores: $stores, total_count: $total_count, items: $items)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$StoreDealsImpl &&
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
      postal_code,
      const DeepCollectionEquality().hash(_stores),
      total_count,
      const DeepCollectionEquality().hash(_items));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$StoreDealsImplCopyWith<_$StoreDealsImpl> get copyWith =>
      __$$StoreDealsImplCopyWithImpl<_$StoreDealsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$StoreDealsImplToJson(
      this,
    );
  }
}

abstract class _StoreDeals implements StoreDeals {
  const factory _StoreDeals(
      {final String? postal_code,
      final List<DealStore> stores,
      final int total_count,
      final List<DealItem> items}) = _$StoreDealsImpl;

  factory _StoreDeals.fromJson(Map<String, dynamic> json) =
      _$StoreDealsImpl.fromJson;

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
  _$$StoreDealsImplCopyWith<_$StoreDealsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
