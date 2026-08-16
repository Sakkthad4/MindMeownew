import 'dart:ui';

class ExercisePoseGeometry {
  const ExercisePoseGeometry._();

  static double bodyRelativeX({
    required double pointX,
    required double leftShoulderX,
    required double rightShoulderX,
  }) {
    final width = (rightShoulderX - leftShoulderX).abs();
    if (width == 0) return 0;
    final center = (leftShoulderX + rightShoulderX) / 2;
    final bodyRightDirection = (rightShoulderX - leftShoulderX).sign;
    return ((pointX - center) * bodyRightDirection) / width;
  }

  static bool isCrossBodyShoulder({
    required bool rightArm,
    required Offset leftShoulder,
    required Offset rightShoulder,
    required Offset activeShoulder,
    Offset? activeElbow,
    Offset? activeWrist,
  }) {
    final shoulderWidth = (rightShoulder.dx - leftShoulder.dx).abs();
    if (shoulderWidth < 0.04) return false;

    final points = [
      if (activeElbow != null) activeElbow,
      if (activeWrist != null) activeWrist,
    ];
    if (points.isEmpty) return false;

    double bodyX(Offset point) => bodyRelativeX(
      pointX: point.dx,
      leftShoulderX: leftShoulder.dx,
      rightShoulderX: rightShoulder.dx,
    );

    final crossedCenter = points.any(
      (point) => rightArm ? bodyX(point) < 0.12 : bodyX(point) > -0.12,
    );
    final nearChestHeight = points.any(
      (point) => (point.dy - activeShoulder.dy).abs() < 0.34,
    );
    final reachesAcross = points.any(
      (point) => (point.dx - activeShoulder.dx).abs() > shoulderWidth * 0.38,
    );

    return crossedCenter && nearChestHeight && reachesAcross;
  }
}
