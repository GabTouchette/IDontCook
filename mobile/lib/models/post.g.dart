// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PostImpl _$$PostImplFromJson(Map<String, dynamic> json) => _$PostImpl(
      id: (json['id'] as num).toInt(),
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      recipe_id: (json['recipe_id'] as num?)?.toInt(),
      recipe_title: json['recipe_title'] as String?,
      recipe_description: json['recipe_description'] as String?,
      recipe_image_url: json['recipe_image_url'] as String?,
      content: json['content'] as String?,
      created_at: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updated_at: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
      upvote_count: (json['upvote_count'] as num?)?.toInt() ?? 0,
      downvote_count: (json['downvote_count'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$PostImplToJson(_$PostImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user': instance.user,
      'recipe_id': instance.recipe_id,
      'recipe_title': instance.recipe_title,
      'recipe_description': instance.recipe_description,
      'recipe_image_url': instance.recipe_image_url,
      'content': instance.content,
      'created_at': instance.created_at?.toIso8601String(),
      'updated_at': instance.updated_at?.toIso8601String(),
      'upvote_count': instance.upvote_count,
      'downvote_count': instance.downvote_count,
    };
