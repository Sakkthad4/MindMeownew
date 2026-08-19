#include "Sensor.h"
#include "Config.h"

namespace {
bool sensorEnabled = true;
bool touched = false;
bool touchChanged = true;
uint32_t rawValue = 0;
uint32_t baseline = 0;
bool candidateState = false;
uint8_t candidateCount = 0;
uint32_t lastReadAt = 0;
uint32_t lastLogAt = 0;

constexpr uint8_t kCalibrationSamples = 32;
constexpr uint8_t kDebounceSamples = 3;
constexpr uint32_t kReadIntervalMs = 30;
constexpr uint32_t kLogIntervalMs = 500;

void updateDebouncedState(bool sampleTouched) {
  if (sampleTouched != candidateState) {
    candidateState = sampleTouched;
    candidateCount = 1;
    return;
  }
  if (candidateCount < kDebounceSamples) ++candidateCount;
  if (candidateCount >= kDebounceSamples && touched != candidateState) {
    touched = candidateState;
    touchChanged = true;
    Serial.printf("[Touch] state=%s raw=%lu baseline=%lu\n",
                  touched ? "touched" : "released",
                  static_cast<unsigned long>(rawValue),
                  static_cast<unsigned long>(baseline));
  }
}
}  // namespace

void Sensor_begin() {
  uint64_t total = 0;
  for (uint8_t i = 0; i < kCalibrationSamples; ++i) {
    total += touchRead(TOUCH_HEAD);
    delay(10);
  }
  baseline = static_cast<uint32_t>(total / kCalibrationSamples);
  rawValue = baseline;
  candidateState = false;
  candidateCount = 0;
  touched = false;
  touchChanged = true;

  Serial.printf("[Touch] Ready GPIO=%d baseline=%lu\n", TOUCH_HEAD,
                static_cast<unsigned long>(baseline));
}

void Sensor_update() {
  const uint32_t now = millis();
  if (now - lastReadAt < kReadIntervalMs) return;
  lastReadAt = now;

  rawValue = touchRead(TOUCH_HEAD);
  if (sensorEnabled && baseline > 0 && rawValue > 0) {
    // A touch lowers the ESP32-S3 capacitive reading. Separate thresholds give
    // hysteresis, while three consecutive samples suppress short spikes.
    const uint32_t threshold = touched ? baseline * 82 / 100 : baseline * 72 / 100;
    updateDebouncedState(rawValue < threshold);

    // Slowly follow environmental drift only while no touch is active.
    if (!touched && rawValue > baseline * 85 / 100) {
      baseline = (baseline * 63 + rawValue) / 64;
    }
  } else if (touched) {
    touched = false;
    touchChanged = true;
  }

  if (now - lastLogAt >= kLogIntervalMs) {
    lastLogAt = now;
    Serial.printf("[Touch] raw=%lu baseline=%lu touched=%d enabled=%d\n",
                  static_cast<unsigned long>(rawValue),
                  static_cast<unsigned long>(baseline), touched, sensorEnabled);
  }
}

void Sensor_setEnabled(bool enabled) {
  sensorEnabled = enabled;
  if (!enabled && touched) touched = false;
  candidateState = false;
  candidateCount = 0;
  touchChanged = true;
}

bool Sensor_isEnabled() { return sensorEnabled; }
bool Sensor_isTouched() { return touched; }
uint32_t Sensor_getRaw() { return rawValue; }
uint32_t Sensor_getBaseline() { return baseline; }
bool Sensor_touchChanged() { return touchChanged; }
void Sensor_clearTouchChanged() { touchChanged = false; }
