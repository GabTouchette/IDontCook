// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vote.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$VoteImpl _$$VoteImplFromJson(Map<String, dynamic> json) => _$VoteImpl(
      id: (json['id'] as num).toInt(),
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      post: Post.fromJson(json['post'] as Map<String, dynamic>),
      is_upvote: json['is_upvote'] as bool,
      created_at: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$VoteImplToJson(_$VoteImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user': instance.user,
      'post': instance.post,
      'is_upvote': instance.is_upvote,
      'created_at': instance.created_at?.toIso8601String(),
    };
