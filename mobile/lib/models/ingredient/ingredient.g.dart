// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$IngredientImpl _$$IngredientImplFromJson(Map<String, dynamic> json) =>
    _$IngredientImpl(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      quantity: (json['quantity'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
      substitutes: (json['substitutes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      nutrition: json['nutrition'] as Map<String, dynamic>?,
      canonical: (json['canonical'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$IngredientImplToJson(_$IngredientImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'quantity': instance.quantity,
      'unit': instance.unit,
      'substitutes': instance.substitutes,
      'nutrition': instance.nutrition,
      'canonical': instance.canonical,
    };
