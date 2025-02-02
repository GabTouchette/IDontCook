// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ingredient.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$IngredientImpl _$$IngredientImplFromJson(Map<String, dynamic> json) =>
    _$IngredientImpl(
      id: (json['id'] as num?)?.toInt(),
      name: json['name'] as String?,
      substitutes: (json['substitutes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      quantity: json['quantity'] as String?,
      unit_of_measure: json['unit_of_measure'] as String?,
    );

Map<String, dynamic> _$$IngredientImplToJson(_$IngredientImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'substitutes': instance.substitutes,
      'quantity': instance.quantity,
      'unit_of_measure': instance.unit_of_measure,
    };
