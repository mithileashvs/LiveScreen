import 'dart:math' as math;
import '../../models/screen_config.dart' show Position3;

/// Coordinate conventions and transform utilities for LiveScreen 3D venue capture.
///
/// Canonical LiveScreen Coordinate Convention:
/// - Units: metres
/// - Coordinate system: Unity left-handed, Y-up
/// - Origin (0, 0, 0): Front wall floor center (immediately behind screen plane at floor level)
/// - +X Axis: Lateral across auditorium (+X is right, -X is left when standing at screen facing audience)
/// - +Y Axis: Vertical elevation above floor level (+Y is up)
/// - +Z Axis: Depth from front wall toward back of auditorium (+Z goes toward rear wall)
///
/// Rotation Convention:
/// - Angles in degrees around the vertical (Y) axis.
/// - Audience seats facing the screen at Z=0 face in the -Z direction.
/// - In LiveScreen's Unity generator: `Quaternion.Euler(0, 180 + rotationY, 0)`
///   where rotationY = 0 faces directly towards -Z (the screen).
/// - Screen facing the audience faces along +Z into the room.
class CoordinateTransformer {
  /// Verifies whether a given position lies within the auditorium bounding box.
  static bool isWithinAuditorium(
    Position3 position, {
    required double roomWidth,
    required double roomLength,
    required double roomHeight,
    double tolerance = 0.05,
  }) {
    final halfWidth = roomWidth / 2.0;
    final inX = position.x >= (-halfWidth - tolerance) &&
        position.x <= (halfWidth + tolerance);
    final inY =
        position.y >= (-tolerance) && position.y <= (roomHeight + tolerance);
    final inZ =
        position.z >= (-tolerance) && position.z <= (roomLength + tolerance);
    return inX && inY && inZ;
  }

  /// Calculates the forward unit vector for a seat given its [rotationY] in degrees.
  /// When [rotationY] == 0, the seat faces directly towards -Z.
  static Position3 seatForwardVector(double rotationY) {
    // rotationY = 0 -> facing (0, 0, -1)
    final radians = (rotationY) * (math.pi / 180.0);
    final x = -math.sin(radians);
    final z = -math.cos(radians);
    return Position3(x: x, y: 0.0, z: z);
  }

  /// Converts a coordinate from a camera-centric OpenCV frame
  /// (Right-handed: X-right, Y-down, Z-forward into camera view)
  /// given the camera's world position and yaw/pitch rotation.
  ///
  /// This is a contract helper for future AI vision workers; Phase 1
  /// validates geometric contracts without requiring native CV libraries.
  static Position3 cameraRelativePointToWorld({
    required Position3 cameraPosition,
    required double cameraYawDegrees,
    required Position3 pointInCameraSpace,
  }) {
    // In camera space: X=right, Y=down (invert to Y-up), Z=forward
    final localX = pointInCameraSpace.x;
    final localY = -pointInCameraSpace.y;
    final localZ = pointInCameraSpace.z;

    final rad = cameraYawDegrees * (math.pi / 180.0);
    final worldX =
        cameraPosition.x + (localX * math.cos(rad) + localZ * math.sin(rad));
    final worldY = cameraPosition.y + localY;
    final worldZ =
        cameraPosition.z + (-localX * math.sin(rad) + localZ * math.cos(rad));

    return Position3(x: worldX, y: worldY, z: worldZ);
  }
}
