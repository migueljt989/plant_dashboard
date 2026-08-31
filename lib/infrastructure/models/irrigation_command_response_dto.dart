import '../../domain/entities/irrigation_command_response.dart';

/// DTO para la respuesta del backend al iniciar o detener el riego.
///
/// Mapea las claves snake_case del backend (`status`, `camera_device_id`,
/// `camera_streaming_available`) a campos camelCase. Un `camera_device_id`
/// ausente o con valor JSON `null` se representa como `cameraDeviceId` null.
class IrrigationCommandResponseDto {
  /// Estado resultante: "started" o "stopped".
  final String status;
  final String? cameraDeviceId;
  final bool cameraStreamingAvailable;

  const IrrigationCommandResponseDto({
    required this.status,
    this.cameraDeviceId,
    required this.cameraStreamingAvailable,
  });

  factory IrrigationCommandResponseDto.fromJson(Map<String, dynamic> json) {
    final status = json['status'];
    if (status == null) {
      throw const FormatException('Missing required field: status');
    }
    if (status is! String) {
      throw FormatException(
        'Field "status" must be a String, got ${status.runtimeType}',
      );
    }
    if (status != 'started' && status != 'stopped') {
      throw FormatException(
        'Field "status" must be "started" or "stopped", got "$status"',
      );
    }

    final cameraStreamingAvailable = json['camera_streaming_available'];
    if (cameraStreamingAvailable == null) {
      throw const FormatException(
        'Missing required field: camera_streaming_available',
      );
    }
    if (cameraStreamingAvailable is! bool) {
      throw FormatException(
        'Field "camera_streaming_available" must be a bool, '
        'got ${cameraStreamingAvailable.runtimeType}',
      );
    }

    final cameraDeviceId = json['camera_device_id'];
    if (cameraDeviceId != null && cameraDeviceId is! String) {
      throw FormatException(
        'Field "camera_device_id" must be a String or null, '
        'got ${cameraDeviceId.runtimeType}',
      );
    }

    return IrrigationCommandResponseDto(
      status: status,
      cameraDeviceId: cameraDeviceId as String?,
      cameraStreamingAvailable: cameraStreamingAvailable,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status,
        'camera_device_id': cameraDeviceId,
        'camera_streaming_available': cameraStreamingAvailable,
      };

  IrrigationCommandResponse toEntity() => IrrigationCommandResponse(
        status: status,
        cameraDeviceId: cameraDeviceId,
        cameraStreamingAvailable: cameraStreamingAvailable,
      );
}
