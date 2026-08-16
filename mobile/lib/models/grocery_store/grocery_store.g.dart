// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grocery_store.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$GroceryStoreImpl _$$GroceryStoreImplFromJson(Map<String, dynamic> json) =>
    _$GroceryStoreImpl(
      merchant: json['merchant'] as String,
      merchant_id: (json['merchant_id'] as num).toInt(),
      flyer_id: (json['flyer_id'] as num?)?.toInt(),
      logo_url: json['logo_url'] as String?,
      valid_from: json['valid_from'] as String?,
      valid_to: json['valid_to'] as String?,
      name: json['name'] as String?,
      lat: (json['lat'] as num?)?.toDouble(),
      lng: (json['lng'] as num?)?.toDouble(),
      distance_m: (json['distance_m'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$GroceryStoreImplToJson(_$GroceryStoreImpl instance) =>
    <String, dynamic>{
      'merchant': instance.merchant,
      'merchant_id': instance.merchant_id,
      'flyer_id': instance.flyer_id,
      'logo_url': instance.logo_url,
      'valid_from': instance.valid_from,
      'valid_to': instance.valid_to,
      'name': instance.name,
      'lat': instance.lat,
      'lng': instance.lng,
      'distance_m': instance.distance_m,
    };
