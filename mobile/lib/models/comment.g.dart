// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CommentImpl _$$CommentImplFromJson(Map<String, dynamic> json) =>
    _$CommentImpl(
      id: (json['id'] as num).toInt(),
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      post: Post.fromJson(json['post'] as Map<String, dynamic>),
      content: json['content'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$CommentImplToJson(_$CommentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user': instance.user,
      'post': instance.post,
      'content': instance.content,
      'createdAt': instance.createdAt.toIso8601String(),
    };
