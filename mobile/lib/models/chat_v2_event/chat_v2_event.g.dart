// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_v2_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ChatV2MessageStartImpl _$$ChatV2MessageStartImplFromJson(
        Map<String, dynamic> json) =>
    _$ChatV2MessageStartImpl(
      conversation_id: (json['conversation_id'] as num?)?.toInt(),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$ChatV2MessageStartImplToJson(
        _$ChatV2MessageStartImpl instance) =>
    <String, dynamic>{
      'conversation_id': instance.conversation_id,
      'type': instance.$type,
    };

_$ChatV2TextDeltaImpl _$$ChatV2TextDeltaImplFromJson(
        Map<String, dynamic> json) =>
    _$ChatV2TextDeltaImpl(
      text: json['text'] as String? ?? '',
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$ChatV2TextDeltaImplToJson(
        _$ChatV2TextDeltaImpl instance) =>
    <String, dynamic>{
      'text': instance.text,
      'type': instance.$type,
    };

_$ChatV2BlockEventImpl _$$ChatV2BlockEventImplFromJson(
        Map<String, dynamic> json) =>
    _$ChatV2BlockEventImpl(
      block: Block.fromJson(json['block'] as Map<String, dynamic>),
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$ChatV2BlockEventImplToJson(
        _$ChatV2BlockEventImpl instance) =>
    <String, dynamic>{
      'block': instance.block,
      'type': instance.$type,
    };

_$ChatV2ToolActivityImpl _$$ChatV2ToolActivityImplFromJson(
        Map<String, dynamic> json) =>
    _$ChatV2ToolActivityImpl(
      tool: json['tool'] as String? ?? '',
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$ChatV2ToolActivityImplToJson(
        _$ChatV2ToolActivityImpl instance) =>
    <String, dynamic>{
      'tool': instance.tool,
      'type': instance.$type,
    };

_$ChatV2ErrorImpl _$$ChatV2ErrorImplFromJson(Map<String, dynamic> json) =>
    _$ChatV2ErrorImpl(
      message: json['message'] as String? ?? '',
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$ChatV2ErrorImplToJson(_$ChatV2ErrorImpl instance) =>
    <String, dynamic>{
      'message': instance.message,
      'type': instance.$type,
    };

_$ChatV2DoneImpl _$$ChatV2DoneImplFromJson(Map<String, dynamic> json) =>
    _$ChatV2DoneImpl(
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$ChatV2DoneImplToJson(_$ChatV2DoneImpl instance) =>
    <String, dynamic>{
      'type': instance.$type,
    };

_$ChatV2UnknownImpl _$$ChatV2UnknownImplFromJson(Map<String, dynamic> json) =>
    _$ChatV2UnknownImpl(
      $type: json['type'] as String?,
    );

Map<String, dynamic> _$$ChatV2UnknownImplToJson(_$ChatV2UnknownImpl instance) =>
    <String, dynamic>{
      'type': instance.$type,
    };
