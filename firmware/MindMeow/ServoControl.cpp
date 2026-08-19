#include "ServoControl.h"
#include "Config.h"

#include <ESP32Servo.h>

namespace {
Servo headServo;
Servo tailServo;

bool headEnabled = false;
bool tailEnabled = false;
int headAngle = HEAD_CENTER_ANGLE;
int tailAngle = TAIL_CENTER_ANGLE;
int headTarget = HEAD_CENTER_ANGLE;
int tailTarget = TAIL_CENTER_ANGLE;

bool wagActive = false;
uint8_t wagStep = 0;
uint32_t wagPauseStarted = 0;
uint32_t lastMoveAt = 0;

constexpr int kStepDegrees = 2;
constexpr uint32_t kStepIntervalMs = 15;
constexpr uint32_t kWagPauseMs = 100;

int moveToward(int current, int target) {
  if (current == target) return current;
  const int difference = target - current;
  const int step = min(abs(difference), kStepDegrees);
  return current + (difference > 0 ? step : -step);
}

void updateMovement() {
  const uint32_t now = millis();
  if (now - lastMoveAt < kStepIntervalMs) return;
  lastMoveAt = now;

  if (headEnabled && headAngle != headTarget) {
    headAngle = moveToward(headAngle, headTarget);
    headServo.write(headAngle);
  }
  if (tailEnabled && tailAngle != tailTarget) {
    tailAngle = moveToward(tailAngle, tailTarget);
    tailServo.write(tailAngle);
  }
}

void updateWag() {
  if (!wagActive || !tailEnabled || tailAngle != tailTarget) return;

  const uint32_t now = millis();
  if (wagPauseStarted == 0) {
    wagPauseStarted = now;
    return;
  }
  if (now - wagPauseStarted < kWagPauseMs) return;
  wagPauseStarted = 0;

  ++wagStep;
  switch (wagStep) {
    case 1:
      tailTarget = TAIL_MAX_ANGLE;
      break;
    case 2:
      tailTarget = TAIL_MIN_ANGLE;
      break;
    case 3:
      tailTarget = TAIL_MAX_ANGLE;
      break;
    default:
      tailTarget = TAIL_CENTER_ANGLE;
      wagActive = false;
      wagStep = 0;
      Serial.println("[Servo] Tail wag complete");
      break;
  }
}
}  // namespace

void Servo_begin() {
  // Servos stay detached until explicitly enabled from the app. This avoids an
  // unexpected jump during boot and keeps the default position at 90 degrees.
  headServo.setPeriodHertz(50);
  tailServo.setPeriodHertz(50);
  Serial.println("[Servo] Ready (head/tail disabled, default 90 degrees)");
}

void Servo_update() {
  updateMovement();
  updateWag();
}

bool Servo_setHeadEnabled(bool enabled) {
  if (enabled == headEnabled) return true;
  if (enabled) {
    headServo.attach(SERVO_HEAD, 500, 2500);
    if (!headServo.attached()) return false;
    headServo.write(headAngle);
  } else {
    headServo.detach();
  }
  headEnabled = enabled;
  Serial.printf("[Servo] Head %s\n", enabled ? "enabled" : "disabled");
  return true;
}

bool Servo_setTailEnabled(bool enabled) {
  if (enabled == tailEnabled) return true;
  wagActive = false;
  wagStep = 0;
  if (enabled) {
    tailServo.attach(SERVO_TAIL, 500, 2500);
    if (!tailServo.attached()) return false;
    tailServo.write(tailAngle);
  } else {
    tailServo.detach();
  }
  tailEnabled = enabled;
  Serial.printf("[Servo] Tail %s\n", enabled ? "enabled" : "disabled");
  return true;
}

bool Servo_setHeadAngle(int angle) {
  if (!headEnabled || angle < HEAD_MIN_ANGLE || angle > HEAD_MAX_ANGLE) {
    return false;
  }
  headTarget = angle;
  return true;
}

bool Servo_setTailAngle(int angle) {
  if (!tailEnabled || angle < TAIL_MIN_ANGLE || angle > TAIL_MAX_ANGLE) {
    return false;
  }
  wagActive = false;
  wagStep = 0;
  tailTarget = angle;
  return true;
}

bool Servo_startTailWag() {
  if (!tailEnabled) return false;
  wagActive = true;
  wagStep = 0;
  wagPauseStarted = 0;
  tailTarget = TAIL_MIN_ANGLE;
  Serial.println("[Servo] Tail wag started");
  return true;
}

bool Servo_isHeadEnabled() { return headEnabled; }
bool Servo_isTailEnabled() { return tailEnabled; }
int Servo_getHeadAngle() { return headAngle; }
int Servo_getTailAngle() { return tailAngle; }
bool Servo_isHeadMoving() { return headEnabled && headAngle != headTarget; }
bool Servo_isTailMoving() {
  return tailEnabled && (tailAngle != tailTarget || wagActive);
}
