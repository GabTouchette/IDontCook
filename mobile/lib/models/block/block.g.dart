// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'block.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$TextBlockImpl _$$TextBlockImplFromJson(Map<String, dynamic> json) =>
    _$TextBlockImpl(
      text: json['text'] as String? ?? '',
      $type: json['block_type'] as String?,
    );

Map<String, dynamic> _$$TextBlockImplToJson(_$TextBlockImpl instance) =>
    <String, dynamic>{
      'text': instance.text,
      'block_type': instance.$type,
    };

_$RecipeBlockImpl _$$RecipeBlockImplFromJson(Map<String, dynamic> json) =>
    _$RecipeBlockImpl(
      recipe: Recipe.fromJson(json['recipe'] as Map<String, dynamic>),
      $type: json['block_type'] as String?,
    );

Map<String, dynamic> _$$RecipeBlockImplToJson(_$RecipeBlockImpl instance) =>
    <String, dynamic>{
      'recipe': instance.recipe,
      'block_type': instance.$type,
    };

_$RecipeRefBlockImpl _$$RecipeRefBlockImplFromJson(Map<String, dynamic> json) =>
    _$RecipeRefBlockImpl(
      recipe: RecipeSummary.fromJson(json['recipe'] as Map<String, dynamic>),
      $type: json['block_type'] as String?,
    );

Map<String, dynamic> _$$RecipeRefBlockImplToJson(
        _$RecipeRefBlockImpl instance) =>
    <String, dynamic>{
      'recipe': instance.recipe,
      'block_type': instance.$type,
    };

_$RecipeUpdateBlockImpl _$$RecipeUpdateBlockImplFromJson(
        Map<String, dynamic> json) =>
    _$RecipeUpdateBlockImpl(
      recipe_id: (json['recipe_id'] as num).toInt(),
      changes:
          json['changes'] as Map<String, dynamic>? ?? const <String, dynamic>{},
      $type: json['block_type'] as String?,
    );

Map<String, dynamic> _$$RecipeUpdateBlockImplToJson(
        _$RecipeUpdateBlockImpl instance) =>
    <String, dynamic>{
      'recipe_id': instance.recipe_id,
      'changes': instance.changes,
      'block_type': instance.$type,
    };

_$ModuleBlockImpl _$$ModuleBlockImplFromJson(Map<String, dynamic> json) =>
    _$ModuleBlockImpl(
      module: HomeModule.fromJson(json['module'] as Map<String, dynamic>),
      $type: json['block_type'] as String?,
    );

Map<String, dynamic> _$$ModuleBlockImplToJson(_$ModuleBlockImpl instance) =>
    <String, dynamic>{
      'module': instance.module,
      'block_type': instance.$type,
    };

_$UnknownBlockImpl _$$UnknownBlockImplFromJson(Map<String, dynamic> json) =>
    _$UnknownBlockImpl(
      $type: json['block_type'] as String?,
    );

Map<String, dynamic> _$$UnknownBlockImplToJson(_$UnknownBlockImpl instance) =>
    <String, dynamic>{
      'block_type': instance.$type,
    };
