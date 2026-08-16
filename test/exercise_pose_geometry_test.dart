import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test22/exercise_pose_geometry.dart';

void main() {
  group('cross-body shoulder stretch', () {
    test('accepts a right arm crossing the chest', () {
      expect(
        ExercisePoseGeometry.isCrossBodyShoulder(
          rightArm: true,
          leftShoulder: const Offset(0.65, 0.30),
          rightShoulder: const Offset(0.35, 0.30),
          activeShoulder: const Offset(0.35, 0.30),
          activeElbow: const Offset(0.51, 0.33),
          activeWrist: const Offset(0.64, 0.34),
        ),
        isTrue,
      );
    });

    test('accepts the same right-arm pose in a mirrored image', () {
      expect(
        ExercisePoseGeometry.isCrossBodyShoulder(
          rightArm: true,
          leftShoulder: const Offset(0.35, 0.30),
          rightShoulder: const Offset(0.65, 0.30),
          activeShoulder: const Offset(0.65, 0.30),
          activeElbow: const Offset(0.49, 0.33),
          activeWrist: const Offset(0.36, 0.34),
        ),
        isTrue,
      );
    });

    test('rejects a right arm that stays on its own side', () {
      expect(
        ExercisePoseGeometry.isCrossBodyShoulder(
          rightArm: true,
          leftShoulder: const Offset(0.65, 0.30),
          rightShoulder: const Offset(0.35, 0.30),
          activeShoulder: const Offset(0.35, 0.30),
          activeElbow: const Offset(0.29, 0.40),
          activeWrist: const Offset(0.24, 0.48),
        ),
        isFalse,
      );
    });

    test('accepts a left arm crossing the chest', () {
      expect(
        ExercisePoseGeometry.isCrossBodyShoulder(
          rightArm: false,
          leftShoulder: const Offset(0.65, 0.30),
          rightShoulder: const Offset(0.35, 0.30),
          activeShoulder: const Offset(0.65, 0.30),
          activeElbow: const Offset(0.49, 0.33),
          activeWrist: const Offset(0.36, 0.34),
        ),
        isTrue,
      );
    });
  });
}
