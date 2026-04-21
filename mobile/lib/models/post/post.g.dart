// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PostImpl _$$PostImplFromJson(Map<String, dynamic> json) => _$PostImpl(
      id: (json['id'] as num).toInt(),
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      user_vote: (json['user_vote'] as num).toInt(),
      user_liked: json['user_liked'] as bool,
      upvote_count: (json['upvote_count'] as num).toInt(),
      downvote_count: (json['downvote_count'] as num).toInt(),
      comment_count: (json['comment_count'] as num).toInt(),
      like_count: (json['like_count'] as num).toInt(),
      recipe_thumbs_up_count: (json['recipe_thumbs_up_count'] as num?)?.toInt(),
      recipe_thumbs_down_count:
          (json['recipe_thumbs_down_count'] as num?)?.toInt(),
      user_recipe_vote: (json['user_recipe_vote'] as num?)?.toInt(),
      recipe_id: (json['recipe_id'] as num?)?.toInt(),
      recipe_title: json['recipe_title'] as String?,
      recipe_description: json['recipe_description'] as String?,
      recipe_thumbnail_url: json['recipe_thumbnail_url'] as String?,
      content: json['content'] as String?,
      created_at: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updated_at: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$PostImplToJson(_$PostImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user': instance.user,
      'user_vote': instance.user_vote,
      'user_liked': instance.user_liked,
      'upvote_count': instance.upvote_count,
      'downvote_count': instance.downvote_count,
      'comment_count': instance.comment_count,
      'like_count': instance.like_count,
      'recipe_thumbs_up_count': instance.recipe_thumbs_up_count,
      'recipe_thumbs_down_count': instance.recipe_thumbs_down_count,
      'user_recipe_vote': instance.user_recipe_vote,
      'recipe_id': instance.recipe_id,
      'recipe_title': instance.recipe_title,
      'recipe_description': instance.recipe_description,
      'recipe_thumbnail_url': instance.recipe_thumbnail_url,
      'content': instance.content,
      'created_at': instance.created_at?.toIso8601String(),
      'updated_at': instance.updated_at?.toIso8601String(),
    };
