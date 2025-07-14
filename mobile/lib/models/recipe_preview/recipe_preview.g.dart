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
      thumbnail_url: json['thumbnail_url'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      is_favorite: json['is_favorite'] as bool?,
      is_saved: json['is_saved'] as bool?,
      ingredients_count: (json['ingredients_count'] as num?)?.toInt(),
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
      'thumbnail_url': instance.thumbnail_url,
      'tags': instance.tags,
      'is_favorite': instance.is_favorite,
      'is_saved': instance.is_saved,
      'ingredients_count': instance.ingredients_count,
      'last_visited_at': instance.last_visited_at?.toIso8601String(),
    };
