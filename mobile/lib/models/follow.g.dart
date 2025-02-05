// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follow.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FollowImpl _$$FollowImplFromJson(Map<String, dynamic> json) => _$FollowImpl(
      id: (json['id'] as num).toInt(),
      follower: User.fromJson(json['follower'] as Map<String, dynamic>),
      followed: User.fromJson(json['followed'] as Map<String, dynamic>),
      created_at: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$FollowImplToJson(_$FollowImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'follower': instance.follower,
      'followed': instance.followed,
      'created_at': instance.created_at?.toIso8601String(),
    };
