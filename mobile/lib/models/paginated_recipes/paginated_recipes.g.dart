// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_recipes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PaginatedRecipesImpl _$$PaginatedRecipesImplFromJson(
        Map<String, dynamic> json) =>
    _$PaginatedRecipesImpl(
      count: (json['count'] as num).toInt(),
      results: (json['results'] as List<dynamic>)
          .map((e) => RecipePreview.fromJson(e as Map<String, dynamic>))
          .toList(),
      next: json['next'] as String?,
    );

Map<String, dynamic> _$$PaginatedRecipesImplToJson(
        _$PaginatedRecipesImpl instance) =>
    <String, dynamic>{
      'count': instance.count,
      'results': instance.results,
      'next': instance.next,
    };
