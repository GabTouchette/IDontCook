// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'store_deals.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$StoreDealsImpl _$$StoreDealsImplFromJson(Map<String, dynamic> json) =>
    _$StoreDealsImpl(
      postal_code: json['postal_code'] as String?,
      stores: (json['stores'] as List<dynamic>?)
              ?.map((e) => DealStore.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <DealStore>[],
      total_count: (json['total_count'] as num?)?.toInt() ?? 0,
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => DealItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <DealItem>[],
    );

Map<String, dynamic> _$$StoreDealsImplToJson(_$StoreDealsImpl instance) =>
    <String, dynamic>{
      'postal_code': instance.postal_code,
      'stores': instance.stores,
      'total_count': instance.total_count,
      'items': instance.items,
    };
