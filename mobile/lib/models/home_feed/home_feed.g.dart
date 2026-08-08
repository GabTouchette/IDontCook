// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_feed.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HomeFeedContextImpl _$$HomeFeedContextImplFromJson(
        Map<String, dynamic> json) =>
    _$HomeFeedContextImpl(
      daypart: json['daypart'] as String? ?? '',
      is_weekend: json['is_weekend'] as bool? ?? false,
      mood: json['mood'] as String?,
    );

Map<String, dynamic> _$$HomeFeedContextImplToJson(
        _$HomeFeedContextImpl instance) =>
    <String, dynamic>{
      'daypart': instance.daypart,
      'is_weekend': instance.is_weekend,
      'mood': instance.mood,
    };

_$HomeFeedImpl _$$HomeFeedImplFromJson(Map<String, dynamic> json) =>
    _$HomeFeedImpl(
      feed_id: json['feed_id'] as String? ?? '',
      context: json['context'] == null
          ? const HomeFeedContext()
          : HomeFeedContext.fromJson(json['context'] as Map<String, dynamic>),
      greeting: json['greeting'] as String? ?? '',
      blocks: (json['blocks'] as List<dynamic>?)
              ?.map((e) => Block.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <Block>[],
    );

Map<String, dynamic> _$$HomeFeedImplToJson(_$HomeFeedImpl instance) =>
    <String, dynamic>{
      'feed_id': instance.feed_id,
      'context': instance.context,
      'greeting': instance.greeting,
      'blocks': instance.blocks,
    };
