// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FollowImpl _$$FollowImplFromJson(Map<String, dynamic> json) => _$FollowImpl(
      id: (json['id'] as num).toInt(),
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      followed_user:
          User.fromJson(json['followed_user'] as Map<String, dynamic>),
      created_at: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$FollowImplToJson(_$FollowImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user': instance.user,
      'followed_user': instance.followed_user,
      'created_at': instance.created_at?.toIso8601String(),
    };
