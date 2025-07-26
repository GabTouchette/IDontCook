// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipe.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RecipeImpl _$$RecipeImplFromJson(Map<String, dynamic> json) => _$RecipeImpl(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? "",
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => Ingredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      instructions: (json['instructions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      parent_id: (json['parent_id'] as num?)?.toInt(),
      cooking_time: (json['cooking_time'] as num?)?.toInt(),
      preparation_time: (json['preparation_time'] as num?)?.toInt(),
      servings: (json['servings'] as num?)?.toInt(),
      tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
      description: json['description'] as String?,
      image_url: json['image_url'] as String?,
      thumbnail_url: json['thumbnail_url'] as String?,
      notes: json['notes'] as String?,
      is_favorite: json['is_favorite'] as bool?,
      is_saved: json['is_saved'] as bool?,
      created_at: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      created_by: json['created_by'] == null
          ? null
          : User.fromJson(json['created_by'] as Map<String, dynamic>),
      last_visited_at: json['last_visited_at'] == null
          ? null
          : DateTime.parse(json['last_visited_at'] as String),
      calories: (json['calories'] as num?)?.toDouble(),
      protein: (json['protein'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
      carbs: (json['carbs'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$RecipeImplToJson(_$RecipeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'ingredients': instance.ingredients,
      'instructions': instance.instructions,
      'parent_id': instance.parent_id,
      'cooking_time': instance.cooking_time,
      'preparation_time': instance.preparation_time,
      'servings': instance.servings,
      'tags': instance.tags,
      'description': instance.description,
      'image_url': instance.image_url,
      'thumbnail_url': instance.thumbnail_url,
      'notes': instance.notes,
      'is_favorite': instance.is_favorite,
      'is_saved': instance.is_saved,
      'created_at': instance.created_at?.toIso8601String(),
      'created_by': instance.created_by,
      'last_visited_at': instance.last_visited_at?.toIso8601String(),
      'calories': instance.calories,
      'protein': instance.protein,
      'fat': instance.fat,
      'carbs': instance.carbs,
    };
