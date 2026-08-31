/// Respuesta del backend al iniciar o detener el riego.
class IrrigationCommandResponse {
  /// Estado resultante: "started" o "stopped".
  final String status;
  final String? cameraDeviceId;
  final bool cameraStreamingAvailable;

  const IrrigationCommandResponse({
    required this.status,
    this.cameraDeviceId,
    required this.cameraStreamingAvailable,
  });
}
