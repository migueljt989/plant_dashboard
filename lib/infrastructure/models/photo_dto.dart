import '../../domain/entities/photo.dart';

/// DTO de infraestructura para los metadatos de una foto.
///
/// Realiza la serialización JSON manual (sin codegen), mapeando las claves
/// snake_case del backend a campos camelCase de Dart. Los timestamps se
/// almacenan como String (ISO-8601) en el DTO y se parsean a [DateTime]
/// únicamente en [toEntity].
class PhotoDto {
  final String id;
  final String deviceId;
  final String filename;
  final String filepath;
  final int sizeBytes;
  final String contentType;
  final String capturedAt; // ISO-8601
  final String createdAt; // ISO-8601

  const PhotoDto({
    required this.id,
    required this.deviceId,
    required this.filename,
    required this.filepath,
    required this.sizeBytes,
    required this.contentType,
    required this.capturedAt,
    required this.createdAt,
  });

  factory PhotoDto.fromJson(Map<String, dynamic> json) => PhotoDto(
        id: json['id'] as String,
        deviceId: json['device_id'] as String,
        filename: json['filename'] as String,
        filepath: json['filepath'] as String,
        sizeBytes: json['size_bytes'] as int,
        contentType: json['content_type'] as String,
        capturedAt: json['captured_at'] as String,
        createdAt: json['created_at'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'device_id': deviceId,
        'filename': filename,
        'filepath': filepath,
        'size_bytes': sizeBytes,
        'content_type': contentType,
        'captured_at': capturedAt,
        'created_at': createdAt,
      };

  Photo toEntity() => Photo(
        id: id,
        deviceId: deviceId,
        filename: filename,
        filepath: filepath,
        sizeBytes: sizeBytes,
        contentType: contentType,
        capturedAt: DateTime.parse(capturedAt),
        createdAt: DateTime.parse(createdAt),
      );
}
