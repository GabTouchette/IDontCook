// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'paginated_posts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PaginatedPostsImpl _$$PaginatedPostsImplFromJson(Map<String, dynamic> json) =>
    _$PaginatedPostsImpl(
      count: (json['count'] as num).toInt(),
      results: (json['results'] as List<dynamic>)
          .map((e) => Post.fromJson(e as Map<String, dynamic>))
          .toList(),
      next: json['next'] as String?,
    );

Map<String, dynamic> _$$PaginatedPostsImplToJson(
        _$PaginatedPostsImpl instance) =>
    <String, dynamic>{
      'count': instance.count,
      'results': instance.results,
      'next': instance.next,
    };
