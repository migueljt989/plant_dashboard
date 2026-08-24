enum DeviceType {
  sensor,
  camera,
  irrigation;

  /// Maps the backend string representation to the enum.
  static DeviceType fromString(String value) {
    return DeviceType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DeviceType.sensor,
    );
  }
}
