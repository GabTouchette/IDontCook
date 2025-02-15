import 'package:freezed_annotation/freezed_annotation.dart';

part 'media_type.freezed.dart';
part 'media_type.g.dart';

@freezed
class MediaType with _$MediaType {
  const factory MediaType({
    required String mimeType,
    required String extension,
  }) = _MediaType;

  factory MediaType.fromJson(Map<String, dynamic> json) => _$MediaTypeFromJson(json);
}
