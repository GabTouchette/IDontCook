// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'paginated_posts.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

PaginatedPosts _$PaginatedPostsFromJson(Map<String, dynamic> json) {
  return _PaginatedPosts.fromJson(json);
}

/// @nodoc
mixin _$PaginatedPosts {
  int get count => throw _privateConstructorUsedError;
  List<Post> get results => throw _privateConstructorUsedError;
  String? get next => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PaginatedPostsCopyWith<PaginatedPosts> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PaginatedPostsCopyWith<$Res> {
  factory $PaginatedPostsCopyWith(
          PaginatedPosts value, $Res Function(PaginatedPosts) then) =
      _$PaginatedPostsCopyWithImpl<$Res, PaginatedPosts>;
  @useResult
  $Res call({int count, List<Post> results, String? next});
}

/// @nodoc
class _$PaginatedPostsCopyWithImpl<$Res, $Val extends PaginatedPosts>
    implements $PaginatedPostsCopyWith<$Res> {
  _$PaginatedPostsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? count = null,
    Object? results = null,
    Object? next = freezed,
  }) {
    return _then(_value.copyWith(
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      results: null == results
          ? _value.results
          : results // ignore: cast_nullable_to_non_nullable
              as List<Post>,
      next: freezed == next
          ? _value.next
          : next // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PaginatedPostsImplCopyWith<$Res>
    implements $PaginatedPostsCopyWith<$Res> {
  factory _$$PaginatedPostsImplCopyWith(_$PaginatedPostsImpl value,
          $Res Function(_$PaginatedPostsImpl) then) =
      __$$PaginatedPostsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({int count, List<Post> results, String? next});
}

/// @nodoc
class __$$PaginatedPostsImplCopyWithImpl<$Res>
    extends _$PaginatedPostsCopyWithImpl<$Res, _$PaginatedPostsImpl>
    implements _$$PaginatedPostsImplCopyWith<$Res> {
  __$$PaginatedPostsImplCopyWithImpl(
      _$PaginatedPostsImpl _value, $Res Function(_$PaginatedPostsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? count = null,
    Object? results = null,
    Object? next = freezed,
  }) {
    return _then(_$PaginatedPostsImpl(
      count: null == count
          ? _value.count
          : count // ignore: cast_nullable_to_non_nullable
              as int,
      results: null == results
          ? _value._results
          : results // ignore: cast_nullable_to_non_nullable
              as List<Post>,
      next: freezed == next
          ? _value.next
          : next // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PaginatedPostsImpl implements _PaginatedPosts {
  const _$PaginatedPostsImpl(
      {required this.count, required final List<Post> results, this.next})
      : _results = results;

  factory _$PaginatedPostsImpl.fromJson(Map<String, dynamic> json) =>
      _$$PaginatedPostsImplFromJson(json);

  @override
  final int count;
  final List<Post> _results;
  @override
  List<Post> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @override
  final String? next;

  @override
  String toString() {
    return 'PaginatedPosts(count: $count, results: $results, next: $next)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PaginatedPostsImpl &&
            (identical(other.count, count) || other.count == count) &&
            const DeepCollectionEquality().equals(other._results, _results) &&
            (identical(other.next, next) || other.next == next));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, count, const DeepCollectionEquality().hash(_results), next);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PaginatedPostsImplCopyWith<_$PaginatedPostsImpl> get copyWith =>
      __$$PaginatedPostsImplCopyWithImpl<_$PaginatedPostsImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PaginatedPostsImplToJson(
      this,
    );
  }
}

abstract class _PaginatedPosts implements PaginatedPosts {
  const factory _PaginatedPosts(
      {required final int count,
      required final List<Post> results,
      final String? next}) = _$PaginatedPostsImpl;

  factory _PaginatedPosts.fromJson(Map<String, dynamic> json) =
      _$PaginatedPostsImpl.fromJson;

  @override
  int get count;
  @override
  List<Post> get results;
  @override
  String? get next;
  @override
  @JsonKey(ignore: true)
  _$$PaginatedPostsImplCopyWith<_$PaginatedPostsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
