// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe_preview.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RecipePreviewImpl _$$RecipePreviewImplFromJson(Map<String, dynamic> json) =>
    _$RecipePreviewImpl(
      id: (json['id'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String?,
      preparation_time: (json['preparation_time'] as num?)?.toInt(),
      cooking_time: (json['cooking_time'] as num?)?.toInt(),
      image_url: json['image_url'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      is_favorite: json['is_favorite'] as bool?,
      last_visited_at: json['last_visited_at'] == null
          ? null
          : DateTime.parse(json['last_visited_at'] as String),
    );

Map<String, dynamic> _$$RecipePreviewImplToJson(_$RecipePreviewImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'preparation_time': instance.preparation_time,
      'cooking_time': instance.cooking_time,
      'image_url': instance.image_url,
      'tags': instance.tags,
      'is_favorite': instance.is_favorite,
      'last_visited_at': instance.last_visited_at?.toIso8601String(),
    };
