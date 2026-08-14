// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RecipeSummaryImpl _$$RecipeSummaryImplFromJson(Map<String, dynamic> json) =>
    _$RecipeSummaryImpl(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      image_url: json['image_url'] as String?,
      total_time: (json['total_time'] as num?)?.toInt(),
      calories: (json['calories'] as num?)?.toInt(),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
      is_owned: json['is_owned'] as bool? ?? false,
    );

Map<String, dynamic> _$$RecipeSummaryImplToJson(_$RecipeSummaryImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'image_url': instance.image_url,
      'total_time': instance.total_time,
      'calories': instance.calories,
      'tags': instance.tags,
      'is_owned': instance.is_owned,
    };
