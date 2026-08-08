// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chat_v2_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ChatV2Event _$ChatV2EventFromJson(Map<String, dynamic> json) {
  switch (json['type']) {
    case 'message_start':
      return ChatV2MessageStart.fromJson(json);
    case 'text_delta':
      return ChatV2TextDelta.fromJson(json);
    case 'block':
      return ChatV2BlockEvent.fromJson(json);
    case 'tool_activity':
      return ChatV2ToolActivity.fromJson(json);
    case 'error':
      return ChatV2Error.fromJson(json);
    case 'done':
      return ChatV2Done.fromJson(json);

    default:
      return ChatV2Unknown.fromJson(json);
  }
}

/// @nodoc
mixin _$ChatV2Event {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int? conversation_id) messageStart,
    required TResult Function(String text) textDelta,
    required TResult Function(Block block) block,
    required TResult Function(String tool) toolActivity,
    required TResult Function(String message) error,
    required TResult Function() done,
    required TResult Function() unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int? conversation_id)? messageStart,
    TResult? Function(String text)? textDelta,
    TResult? Function(Block block)? block,
    TResult? Function(String tool)? toolActivity,
    TResult? Function(String message)? error,
    TResult? Function()? done,
    TResult? Function()? unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int? conversation_id)? messageStart,
    TResult Function(String text)? textDelta,
    TResult Function(Block block)? block,
    TResult Function(String tool)? toolActivity,
    TResult Function(String message)? error,
    TResult Function()? done,
    TResult Function()? unknown,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatV2MessageStart value) messageStart,
    required TResult Function(ChatV2TextDelta value) textDelta,
    required TResult Function(ChatV2BlockEvent value) block,
    required TResult Function(ChatV2ToolActivity value) toolActivity,
    required TResult Function(ChatV2Error value) error,
    required TResult Function(ChatV2Done value) done,
    required TResult Function(ChatV2Unknown value) unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatV2MessageStart value)? messageStart,
    TResult? Function(ChatV2TextDelta value)? textDelta,
    TResult? Function(ChatV2BlockEvent value)? block,
    TResult? Function(ChatV2ToolActivity value)? toolActivity,
    TResult? Function(ChatV2Error value)? error,
    TResult? Function(ChatV2Done value)? done,
    TResult? Function(ChatV2Unknown value)? unknown,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatV2MessageStart value)? messageStart,
    TResult Function(ChatV2TextDelta value)? textDelta,
    TResult Function(ChatV2BlockEvent value)? block,
    TResult Function(ChatV2ToolActivity value)? toolActivity,
    TResult Function(ChatV2Error value)? error,
    TResult Function(ChatV2Done value)? done,
    TResult Function(ChatV2Unknown value)? unknown,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ChatV2EventCopyWith<$Res> {
  factory $ChatV2EventCopyWith(
          ChatV2Event value, $Res Function(ChatV2Event) then) =
      _$ChatV2EventCopyWithImpl<$Res, ChatV2Event>;
}

/// @nodoc
class _$ChatV2EventCopyWithImpl<$Res, $Val extends ChatV2Event>
    implements $ChatV2EventCopyWith<$Res> {
  _$ChatV2EventCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$ChatV2MessageStartImplCopyWith<$Res> {
  factory _$$ChatV2MessageStartImplCopyWith(_$ChatV2MessageStartImpl value,
          $Res Function(_$ChatV2MessageStartImpl) then) =
      __$$ChatV2MessageStartImplCopyWithImpl<$Res>;
  @useResult
  $Res call({int? conversation_id});
}

/// @nodoc
class __$$ChatV2MessageStartImplCopyWithImpl<$Res>
    extends _$ChatV2EventCopyWithImpl<$Res, _$ChatV2MessageStartImpl>
    implements _$$ChatV2MessageStartImplCopyWith<$Res> {
  __$$ChatV2MessageStartImplCopyWithImpl(_$ChatV2MessageStartImpl _value,
      $Res Function(_$ChatV2MessageStartImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? conversation_id = freezed,
  }) {
    return _then(_$ChatV2MessageStartImpl(
      conversation_id: freezed == conversation_id
          ? _value.conversation_id
          : conversation_id // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatV2MessageStartImpl implements ChatV2MessageStart {
  const _$ChatV2MessageStartImpl({this.conversation_id, final String? $type})
      : $type = $type ?? 'message_start';

  factory _$ChatV2MessageStartImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatV2MessageStartImplFromJson(json);

  @override
  final int? conversation_id;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'ChatV2Event.messageStart(conversation_id: $conversation_id)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatV2MessageStartImpl &&
            (identical(other.conversation_id, conversation_id) ||
                other.conversation_id == conversation_id));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, conversation_id);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatV2MessageStartImplCopyWith<_$ChatV2MessageStartImpl> get copyWith =>
      __$$ChatV2MessageStartImplCopyWithImpl<_$ChatV2MessageStartImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int? conversation_id) messageStart,
    required TResult Function(String text) textDelta,
    required TResult Function(Block block) block,
    required TResult Function(String tool) toolActivity,
    required TResult Function(String message) error,
    required TResult Function() done,
    required TResult Function() unknown,
  }) {
    return messageStart(conversation_id);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int? conversation_id)? messageStart,
    TResult? Function(String text)? textDelta,
    TResult? Function(Block block)? block,
    TResult? Function(String tool)? toolActivity,
    TResult? Function(String message)? error,
    TResult? Function()? done,
    TResult? Function()? unknown,
  }) {
    return messageStart?.call(conversation_id);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int? conversation_id)? messageStart,
    TResult Function(String text)? textDelta,
    TResult Function(Block block)? block,
    TResult Function(String tool)? toolActivity,
    TResult Function(String message)? error,
    TResult Function()? done,
    TResult Function()? unknown,
    required TResult orElse(),
  }) {
    if (messageStart != null) {
      return messageStart(conversation_id);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatV2MessageStart value) messageStart,
    required TResult Function(ChatV2TextDelta value) textDelta,
    required TResult Function(ChatV2BlockEvent value) block,
    required TResult Function(ChatV2ToolActivity value) toolActivity,
    required TResult Function(ChatV2Error value) error,
    required TResult Function(ChatV2Done value) done,
    required TResult Function(ChatV2Unknown value) unknown,
  }) {
    return messageStart(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatV2MessageStart value)? messageStart,
    TResult? Function(ChatV2TextDelta value)? textDelta,
    TResult? Function(ChatV2BlockEvent value)? block,
    TResult? Function(ChatV2ToolActivity value)? toolActivity,
    TResult? Function(ChatV2Error value)? error,
    TResult? Function(ChatV2Done value)? done,
    TResult? Function(ChatV2Unknown value)? unknown,
  }) {
    return messageStart?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatV2MessageStart value)? messageStart,
    TResult Function(ChatV2TextDelta value)? textDelta,
    TResult Function(ChatV2BlockEvent value)? block,
    TResult Function(ChatV2ToolActivity value)? toolActivity,
    TResult Function(ChatV2Error value)? error,
    TResult Function(ChatV2Done value)? done,
    TResult Function(ChatV2Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (messageStart != null) {
      return messageStart(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatV2MessageStartImplToJson(
      this,
    );
  }
}

abstract class ChatV2MessageStart implements ChatV2Event {
  const factory ChatV2MessageStart({final int? conversation_id}) =
      _$ChatV2MessageStartImpl;

  factory ChatV2MessageStart.fromJson(Map<String, dynamic> json) =
      _$ChatV2MessageStartImpl.fromJson;

  int? get conversation_id;
  @JsonKey(ignore: true)
  _$$ChatV2MessageStartImplCopyWith<_$ChatV2MessageStartImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ChatV2TextDeltaImplCopyWith<$Res> {
  factory _$$ChatV2TextDeltaImplCopyWith(_$ChatV2TextDeltaImpl value,
          $Res Function(_$ChatV2TextDeltaImpl) then) =
      __$$ChatV2TextDeltaImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String text});
}

/// @nodoc
class __$$ChatV2TextDeltaImplCopyWithImpl<$Res>
    extends _$ChatV2EventCopyWithImpl<$Res, _$ChatV2TextDeltaImpl>
    implements _$$ChatV2TextDeltaImplCopyWith<$Res> {
  __$$ChatV2TextDeltaImplCopyWithImpl(
      _$ChatV2TextDeltaImpl _value, $Res Function(_$ChatV2TextDeltaImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? text = null,
  }) {
    return _then(_$ChatV2TextDeltaImpl(
      text: null == text
          ? _value.text
          : text // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatV2TextDeltaImpl implements ChatV2TextDelta {
  const _$ChatV2TextDeltaImpl({this.text = '', final String? $type})
      : $type = $type ?? 'text_delta';

  factory _$ChatV2TextDeltaImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatV2TextDeltaImplFromJson(json);

  @override
  @JsonKey()
  final String text;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'ChatV2Event.textDelta(text: $text)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatV2TextDeltaImpl &&
            (identical(other.text, text) || other.text == text));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, text);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatV2TextDeltaImplCopyWith<_$ChatV2TextDeltaImpl> get copyWith =>
      __$$ChatV2TextDeltaImplCopyWithImpl<_$ChatV2TextDeltaImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int? conversation_id) messageStart,
    required TResult Function(String text) textDelta,
    required TResult Function(Block block) block,
    required TResult Function(String tool) toolActivity,
    required TResult Function(String message) error,
    required TResult Function() done,
    required TResult Function() unknown,
  }) {
    return textDelta(text);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int? conversation_id)? messageStart,
    TResult? Function(String text)? textDelta,
    TResult? Function(Block block)? block,
    TResult? Function(String tool)? toolActivity,
    TResult? Function(String message)? error,
    TResult? Function()? done,
    TResult? Function()? unknown,
  }) {
    return textDelta?.call(text);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int? conversation_id)? messageStart,
    TResult Function(String text)? textDelta,
    TResult Function(Block block)? block,
    TResult Function(String tool)? toolActivity,
    TResult Function(String message)? error,
    TResult Function()? done,
    TResult Function()? unknown,
    required TResult orElse(),
  }) {
    if (textDelta != null) {
      return textDelta(text);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatV2MessageStart value) messageStart,
    required TResult Function(ChatV2TextDelta value) textDelta,
    required TResult Function(ChatV2BlockEvent value) block,
    required TResult Function(ChatV2ToolActivity value) toolActivity,
    required TResult Function(ChatV2Error value) error,
    required TResult Function(ChatV2Done value) done,
    required TResult Function(ChatV2Unknown value) unknown,
  }) {
    return textDelta(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatV2MessageStart value)? messageStart,
    TResult? Function(ChatV2TextDelta value)? textDelta,
    TResult? Function(ChatV2BlockEvent value)? block,
    TResult? Function(ChatV2ToolActivity value)? toolActivity,
    TResult? Function(ChatV2Error value)? error,
    TResult? Function(ChatV2Done value)? done,
    TResult? Function(ChatV2Unknown value)? unknown,
  }) {
    return textDelta?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatV2MessageStart value)? messageStart,
    TResult Function(ChatV2TextDelta value)? textDelta,
    TResult Function(ChatV2BlockEvent value)? block,
    TResult Function(ChatV2ToolActivity value)? toolActivity,
    TResult Function(ChatV2Error value)? error,
    TResult Function(ChatV2Done value)? done,
    TResult Function(ChatV2Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (textDelta != null) {
      return textDelta(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatV2TextDeltaImplToJson(
      this,
    );
  }
}

abstract class ChatV2TextDelta implements ChatV2Event {
  const factory ChatV2TextDelta({final String text}) = _$ChatV2TextDeltaImpl;

  factory ChatV2TextDelta.fromJson(Map<String, dynamic> json) =
      _$ChatV2TextDeltaImpl.fromJson;

  String get text;
  @JsonKey(ignore: true)
  _$$ChatV2TextDeltaImplCopyWith<_$ChatV2TextDeltaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ChatV2BlockEventImplCopyWith<$Res> {
  factory _$$ChatV2BlockEventImplCopyWith(_$ChatV2BlockEventImpl value,
          $Res Function(_$ChatV2BlockEventImpl) then) =
      __$$ChatV2BlockEventImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Block block});

  $BlockCopyWith<$Res> get block;
}

/// @nodoc
class __$$ChatV2BlockEventImplCopyWithImpl<$Res>
    extends _$ChatV2EventCopyWithImpl<$Res, _$ChatV2BlockEventImpl>
    implements _$$ChatV2BlockEventImplCopyWith<$Res> {
  __$$ChatV2BlockEventImplCopyWithImpl(_$ChatV2BlockEventImpl _value,
      $Res Function(_$ChatV2BlockEventImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? block = null,
  }) {
    return _then(_$ChatV2BlockEventImpl(
      block: null == block
          ? _value.block
          : block // ignore: cast_nullable_to_non_nullable
              as Block,
    ));
  }

  @override
  @pragma('vm:prefer-inline')
  $BlockCopyWith<$Res> get block {
    return $BlockCopyWith<$Res>(_value.block, (value) {
      return _then(_value.copyWith(block: value));
    });
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatV2BlockEventImpl implements ChatV2BlockEvent {
  const _$ChatV2BlockEventImpl({required this.block, final String? $type})
      : $type = $type ?? 'block';

  factory _$ChatV2BlockEventImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatV2BlockEventImplFromJson(json);

  @override
  final Block block;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'ChatV2Event.block(block: $block)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatV2BlockEventImpl &&
            (identical(other.block, block) || other.block == block));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, block);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatV2BlockEventImplCopyWith<_$ChatV2BlockEventImpl> get copyWith =>
      __$$ChatV2BlockEventImplCopyWithImpl<_$ChatV2BlockEventImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int? conversation_id) messageStart,
    required TResult Function(String text) textDelta,
    required TResult Function(Block block) block,
    required TResult Function(String tool) toolActivity,
    required TResult Function(String message) error,
    required TResult Function() done,
    required TResult Function() unknown,
  }) {
    return block(this.block);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int? conversation_id)? messageStart,
    TResult? Function(String text)? textDelta,
    TResult? Function(Block block)? block,
    TResult? Function(String tool)? toolActivity,
    TResult? Function(String message)? error,
    TResult? Function()? done,
    TResult? Function()? unknown,
  }) {
    return block?.call(this.block);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int? conversation_id)? messageStart,
    TResult Function(String text)? textDelta,
    TResult Function(Block block)? block,
    TResult Function(String tool)? toolActivity,
    TResult Function(String message)? error,
    TResult Function()? done,
    TResult Function()? unknown,
    required TResult orElse(),
  }) {
    if (block != null) {
      return block(this.block);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatV2MessageStart value) messageStart,
    required TResult Function(ChatV2TextDelta value) textDelta,
    required TResult Function(ChatV2BlockEvent value) block,
    required TResult Function(ChatV2ToolActivity value) toolActivity,
    required TResult Function(ChatV2Error value) error,
    required TResult Function(ChatV2Done value) done,
    required TResult Function(ChatV2Unknown value) unknown,
  }) {
    return block(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatV2MessageStart value)? messageStart,
    TResult? Function(ChatV2TextDelta value)? textDelta,
    TResult? Function(ChatV2BlockEvent value)? block,
    TResult? Function(ChatV2ToolActivity value)? toolActivity,
    TResult? Function(ChatV2Error value)? error,
    TResult? Function(ChatV2Done value)? done,
    TResult? Function(ChatV2Unknown value)? unknown,
  }) {
    return block?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatV2MessageStart value)? messageStart,
    TResult Function(ChatV2TextDelta value)? textDelta,
    TResult Function(ChatV2BlockEvent value)? block,
    TResult Function(ChatV2ToolActivity value)? toolActivity,
    TResult Function(ChatV2Error value)? error,
    TResult Function(ChatV2Done value)? done,
    TResult Function(ChatV2Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (block != null) {
      return block(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatV2BlockEventImplToJson(
      this,
    );
  }
}

abstract class ChatV2BlockEvent implements ChatV2Event {
  const factory ChatV2BlockEvent({required final Block block}) =
      _$ChatV2BlockEventImpl;

  factory ChatV2BlockEvent.fromJson(Map<String, dynamic> json) =
      _$ChatV2BlockEventImpl.fromJson;

  Block get block;
  @JsonKey(ignore: true)
  _$$ChatV2BlockEventImplCopyWith<_$ChatV2BlockEventImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ChatV2ToolActivityImplCopyWith<$Res> {
  factory _$$ChatV2ToolActivityImplCopyWith(_$ChatV2ToolActivityImpl value,
          $Res Function(_$ChatV2ToolActivityImpl) then) =
      __$$ChatV2ToolActivityImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String tool});
}

/// @nodoc
class __$$ChatV2ToolActivityImplCopyWithImpl<$Res>
    extends _$ChatV2EventCopyWithImpl<$Res, _$ChatV2ToolActivityImpl>
    implements _$$ChatV2ToolActivityImplCopyWith<$Res> {
  __$$ChatV2ToolActivityImplCopyWithImpl(_$ChatV2ToolActivityImpl _value,
      $Res Function(_$ChatV2ToolActivityImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tool = null,
  }) {
    return _then(_$ChatV2ToolActivityImpl(
      tool: null == tool
          ? _value.tool
          : tool // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatV2ToolActivityImpl implements ChatV2ToolActivity {
  const _$ChatV2ToolActivityImpl({this.tool = '', final String? $type})
      : $type = $type ?? 'tool_activity';

  factory _$ChatV2ToolActivityImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatV2ToolActivityImplFromJson(json);

  @override
  @JsonKey()
  final String tool;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'ChatV2Event.toolActivity(tool: $tool)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatV2ToolActivityImpl &&
            (identical(other.tool, tool) || other.tool == tool));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, tool);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatV2ToolActivityImplCopyWith<_$ChatV2ToolActivityImpl> get copyWith =>
      __$$ChatV2ToolActivityImplCopyWithImpl<_$ChatV2ToolActivityImpl>(
          this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int? conversation_id) messageStart,
    required TResult Function(String text) textDelta,
    required TResult Function(Block block) block,
    required TResult Function(String tool) toolActivity,
    required TResult Function(String message) error,
    required TResult Function() done,
    required TResult Function() unknown,
  }) {
    return toolActivity(tool);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int? conversation_id)? messageStart,
    TResult? Function(String text)? textDelta,
    TResult? Function(Block block)? block,
    TResult? Function(String tool)? toolActivity,
    TResult? Function(String message)? error,
    TResult? Function()? done,
    TResult? Function()? unknown,
  }) {
    return toolActivity?.call(tool);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int? conversation_id)? messageStart,
    TResult Function(String text)? textDelta,
    TResult Function(Block block)? block,
    TResult Function(String tool)? toolActivity,
    TResult Function(String message)? error,
    TResult Function()? done,
    TResult Function()? unknown,
    required TResult orElse(),
  }) {
    if (toolActivity != null) {
      return toolActivity(tool);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatV2MessageStart value) messageStart,
    required TResult Function(ChatV2TextDelta value) textDelta,
    required TResult Function(ChatV2BlockEvent value) block,
    required TResult Function(ChatV2ToolActivity value) toolActivity,
    required TResult Function(ChatV2Error value) error,
    required TResult Function(ChatV2Done value) done,
    required TResult Function(ChatV2Unknown value) unknown,
  }) {
    return toolActivity(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatV2MessageStart value)? messageStart,
    TResult? Function(ChatV2TextDelta value)? textDelta,
    TResult? Function(ChatV2BlockEvent value)? block,
    TResult? Function(ChatV2ToolActivity value)? toolActivity,
    TResult? Function(ChatV2Error value)? error,
    TResult? Function(ChatV2Done value)? done,
    TResult? Function(ChatV2Unknown value)? unknown,
  }) {
    return toolActivity?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatV2MessageStart value)? messageStart,
    TResult Function(ChatV2TextDelta value)? textDelta,
    TResult Function(ChatV2BlockEvent value)? block,
    TResult Function(ChatV2ToolActivity value)? toolActivity,
    TResult Function(ChatV2Error value)? error,
    TResult Function(ChatV2Done value)? done,
    TResult Function(ChatV2Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (toolActivity != null) {
      return toolActivity(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatV2ToolActivityImplToJson(
      this,
    );
  }
}

abstract class ChatV2ToolActivity implements ChatV2Event {
  const factory ChatV2ToolActivity({final String tool}) =
      _$ChatV2ToolActivityImpl;

  factory ChatV2ToolActivity.fromJson(Map<String, dynamic> json) =
      _$ChatV2ToolActivityImpl.fromJson;

  String get tool;
  @JsonKey(ignore: true)
  _$$ChatV2ToolActivityImplCopyWith<_$ChatV2ToolActivityImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ChatV2ErrorImplCopyWith<$Res> {
  factory _$$ChatV2ErrorImplCopyWith(
          _$ChatV2ErrorImpl value, $Res Function(_$ChatV2ErrorImpl) then) =
      __$$ChatV2ErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$ChatV2ErrorImplCopyWithImpl<$Res>
    extends _$ChatV2EventCopyWithImpl<$Res, _$ChatV2ErrorImpl>
    implements _$$ChatV2ErrorImplCopyWith<$Res> {
  __$$ChatV2ErrorImplCopyWithImpl(
      _$ChatV2ErrorImpl _value, $Res Function(_$ChatV2ErrorImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? message = null,
  }) {
    return _then(_$ChatV2ErrorImpl(
      message: null == message
          ? _value.message
          : message // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ChatV2ErrorImpl implements ChatV2Error {
  const _$ChatV2ErrorImpl({this.message = '', final String? $type})
      : $type = $type ?? 'error';

  factory _$ChatV2ErrorImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatV2ErrorImplFromJson(json);

  @override
  @JsonKey()
  final String message;

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'ChatV2Event.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ChatV2ErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, message);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ChatV2ErrorImplCopyWith<_$ChatV2ErrorImpl> get copyWith =>
      __$$ChatV2ErrorImplCopyWithImpl<_$ChatV2ErrorImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int? conversation_id) messageStart,
    required TResult Function(String text) textDelta,
    required TResult Function(Block block) block,
    required TResult Function(String tool) toolActivity,
    required TResult Function(String message) error,
    required TResult Function() done,
    required TResult Function() unknown,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int? conversation_id)? messageStart,
    TResult? Function(String text)? textDelta,
    TResult? Function(Block block)? block,
    TResult? Function(String tool)? toolActivity,
    TResult? Function(String message)? error,
    TResult? Function()? done,
    TResult? Function()? unknown,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int? conversation_id)? messageStart,
    TResult Function(String text)? textDelta,
    TResult Function(Block block)? block,
    TResult Function(String tool)? toolActivity,
    TResult Function(String message)? error,
    TResult Function()? done,
    TResult Function()? unknown,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatV2MessageStart value) messageStart,
    required TResult Function(ChatV2TextDelta value) textDelta,
    required TResult Function(ChatV2BlockEvent value) block,
    required TResult Function(ChatV2ToolActivity value) toolActivity,
    required TResult Function(ChatV2Error value) error,
    required TResult Function(ChatV2Done value) done,
    required TResult Function(ChatV2Unknown value) unknown,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatV2MessageStart value)? messageStart,
    TResult? Function(ChatV2TextDelta value)? textDelta,
    TResult? Function(ChatV2BlockEvent value)? block,
    TResult? Function(ChatV2ToolActivity value)? toolActivity,
    TResult? Function(ChatV2Error value)? error,
    TResult? Function(ChatV2Done value)? done,
    TResult? Function(ChatV2Unknown value)? unknown,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatV2MessageStart value)? messageStart,
    TResult Function(ChatV2TextDelta value)? textDelta,
    TResult Function(ChatV2BlockEvent value)? block,
    TResult Function(ChatV2ToolActivity value)? toolActivity,
    TResult Function(ChatV2Error value)? error,
    TResult Function(ChatV2Done value)? done,
    TResult Function(ChatV2Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatV2ErrorImplToJson(
      this,
    );
  }
}

abstract class ChatV2Error implements ChatV2Event {
  const factory ChatV2Error({final String message}) = _$ChatV2ErrorImpl;

  factory ChatV2Error.fromJson(Map<String, dynamic> json) =
      _$ChatV2ErrorImpl.fromJson;

  String get message;
  @JsonKey(ignore: true)
  _$$ChatV2ErrorImplCopyWith<_$ChatV2ErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$ChatV2DoneImplCopyWith<$Res> {
  factory _$$ChatV2DoneImplCopyWith(
          _$ChatV2DoneImpl value, $Res Function(_$ChatV2DoneImpl) then) =
      __$$ChatV2DoneImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ChatV2DoneImplCopyWithImpl<$Res>
    extends _$ChatV2EventCopyWithImpl<$Res, _$ChatV2DoneImpl>
    implements _$$ChatV2DoneImplCopyWith<$Res> {
  __$$ChatV2DoneImplCopyWithImpl(
      _$ChatV2DoneImpl _value, $Res Function(_$ChatV2DoneImpl) _then)
      : super(_value, _then);
}

/// @nodoc
@JsonSerializable()
class _$ChatV2DoneImpl implements ChatV2Done {
  const _$ChatV2DoneImpl({final String? $type}) : $type = $type ?? 'done';

  factory _$ChatV2DoneImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatV2DoneImplFromJson(json);

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'ChatV2Event.done()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$ChatV2DoneImpl);
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int? conversation_id) messageStart,
    required TResult Function(String text) textDelta,
    required TResult Function(Block block) block,
    required TResult Function(String tool) toolActivity,
    required TResult Function(String message) error,
    required TResult Function() done,
    required TResult Function() unknown,
  }) {
    return done();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int? conversation_id)? messageStart,
    TResult? Function(String text)? textDelta,
    TResult? Function(Block block)? block,
    TResult? Function(String tool)? toolActivity,
    TResult? Function(String message)? error,
    TResult? Function()? done,
    TResult? Function()? unknown,
  }) {
    return done?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int? conversation_id)? messageStart,
    TResult Function(String text)? textDelta,
    TResult Function(Block block)? block,
    TResult Function(String tool)? toolActivity,
    TResult Function(String message)? error,
    TResult Function()? done,
    TResult Function()? unknown,
    required TResult orElse(),
  }) {
    if (done != null) {
      return done();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatV2MessageStart value) messageStart,
    required TResult Function(ChatV2TextDelta value) textDelta,
    required TResult Function(ChatV2BlockEvent value) block,
    required TResult Function(ChatV2ToolActivity value) toolActivity,
    required TResult Function(ChatV2Error value) error,
    required TResult Function(ChatV2Done value) done,
    required TResult Function(ChatV2Unknown value) unknown,
  }) {
    return done(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatV2MessageStart value)? messageStart,
    TResult? Function(ChatV2TextDelta value)? textDelta,
    TResult? Function(ChatV2BlockEvent value)? block,
    TResult? Function(ChatV2ToolActivity value)? toolActivity,
    TResult? Function(ChatV2Error value)? error,
    TResult? Function(ChatV2Done value)? done,
    TResult? Function(ChatV2Unknown value)? unknown,
  }) {
    return done?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatV2MessageStart value)? messageStart,
    TResult Function(ChatV2TextDelta value)? textDelta,
    TResult Function(ChatV2BlockEvent value)? block,
    TResult Function(ChatV2ToolActivity value)? toolActivity,
    TResult Function(ChatV2Error value)? error,
    TResult Function(ChatV2Done value)? done,
    TResult Function(ChatV2Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (done != null) {
      return done(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatV2DoneImplToJson(
      this,
    );
  }
}

abstract class ChatV2Done implements ChatV2Event {
  const factory ChatV2Done() = _$ChatV2DoneImpl;

  factory ChatV2Done.fromJson(Map<String, dynamic> json) =
      _$ChatV2DoneImpl.fromJson;
}

/// @nodoc
abstract class _$$ChatV2UnknownImplCopyWith<$Res> {
  factory _$$ChatV2UnknownImplCopyWith(
          _$ChatV2UnknownImpl value, $Res Function(_$ChatV2UnknownImpl) then) =
      __$$ChatV2UnknownImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$ChatV2UnknownImplCopyWithImpl<$Res>
    extends _$ChatV2EventCopyWithImpl<$Res, _$ChatV2UnknownImpl>
    implements _$$ChatV2UnknownImplCopyWith<$Res> {
  __$$ChatV2UnknownImplCopyWithImpl(
      _$ChatV2UnknownImpl _value, $Res Function(_$ChatV2UnknownImpl) _then)
      : super(_value, _then);
}

/// @nodoc
@JsonSerializable()
class _$ChatV2UnknownImpl implements ChatV2Unknown {
  const _$ChatV2UnknownImpl({final String? $type}) : $type = $type ?? 'unknown';

  factory _$ChatV2UnknownImpl.fromJson(Map<String, dynamic> json) =>
      _$$ChatV2UnknownImplFromJson(json);

  @JsonKey(name: 'type')
  final String $type;

  @override
  String toString() {
    return 'ChatV2Event.unknown()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$ChatV2UnknownImpl);
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(int? conversation_id) messageStart,
    required TResult Function(String text) textDelta,
    required TResult Function(Block block) block,
    required TResult Function(String tool) toolActivity,
    required TResult Function(String message) error,
    required TResult Function() done,
    required TResult Function() unknown,
  }) {
    return unknown();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(int? conversation_id)? messageStart,
    TResult? Function(String text)? textDelta,
    TResult? Function(Block block)? block,
    TResult? Function(String tool)? toolActivity,
    TResult? Function(String message)? error,
    TResult? Function()? done,
    TResult? Function()? unknown,
  }) {
    return unknown?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(int? conversation_id)? messageStart,
    TResult Function(String text)? textDelta,
    TResult Function(Block block)? block,
    TResult Function(String tool)? toolActivity,
    TResult Function(String message)? error,
    TResult Function()? done,
    TResult Function()? unknown,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(ChatV2MessageStart value) messageStart,
    required TResult Function(ChatV2TextDelta value) textDelta,
    required TResult Function(ChatV2BlockEvent value) block,
    required TResult Function(ChatV2ToolActivity value) toolActivity,
    required TResult Function(ChatV2Error value) error,
    required TResult Function(ChatV2Done value) done,
    required TResult Function(ChatV2Unknown value) unknown,
  }) {
    return unknown(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(ChatV2MessageStart value)? messageStart,
    TResult? Function(ChatV2TextDelta value)? textDelta,
    TResult? Function(ChatV2BlockEvent value)? block,
    TResult? Function(ChatV2ToolActivity value)? toolActivity,
    TResult? Function(ChatV2Error value)? error,
    TResult? Function(ChatV2Done value)? done,
    TResult? Function(ChatV2Unknown value)? unknown,
  }) {
    return unknown?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(ChatV2MessageStart value)? messageStart,
    TResult Function(ChatV2TextDelta value)? textDelta,
    TResult Function(ChatV2BlockEvent value)? block,
    TResult Function(ChatV2ToolActivity value)? toolActivity,
    TResult Function(ChatV2Error value)? error,
    TResult Function(ChatV2Done value)? done,
    TResult Function(ChatV2Unknown value)? unknown,
    required TResult orElse(),
  }) {
    if (unknown != null) {
      return unknown(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$ChatV2UnknownImplToJson(
      this,
    );
  }
}

abstract class ChatV2Unknown implements ChatV2Event {
  const factory ChatV2Unknown() = _$ChatV2UnknownImpl;

  factory ChatV2Unknown.fromJson(Map<String, dynamic> json) =
      _$ChatV2UnknownImpl.fromJson;
}
