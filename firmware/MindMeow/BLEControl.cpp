#include "BLEControl.h"

#include "Config.h"
#include "Eyes.h"
#include "Sensor.h"
#include "ServoControl.h"

#include <ArduinoJson.h>
#include <NimBLEDevice.h>
#include <freertos/FreeRTOS.h>
#include <freertos/queue.h>

namespace {
NimBLEServer* bleServer = nullptr;
NimBLEAdvertising* bleAdvertising = nullptr;
NimBLECharacteristic* commandCharacteristic = nullptr;
NimBLECharacteristic* eventCharacteristic = nullptr;
QueueHandle_t commandQueue = nullptr;

volatile bool connected = false;
volatile bool advertisingRestartPending = false;
volatile bool commandOverflow = false;
bool bleReady = false;
uint32_t disconnectedAt = 0;
uint32_t lastTouchNotifyAt = 0;

constexpr uint32_t kAdvertisingRestartDelayMs = 150;
constexpr uint32_t kTouchNotifyIntervalMs = 250;
constexpr size_t kCommandCapacity = 192;

struct CommandPacket {
  char json[kCommandCapacity];
  bool truncated;
};

void sendDocument(JsonDocument& document) {
  if (eventCharacteristic == nullptr) return;

  char output[244];
  const size_t length = serializeJson(document, output, sizeof(output));
  if (length == 0 || length >= sizeof(output)) {
    Serial.println("[BLE] Event JSON is too large");
    return;
  }

  eventCharacteristic->setValue(
      reinterpret_cast<const uint8_t*>(output), length);
  Serial.printf("[BLE TX] %s\n", output);
  if (connected && !eventCharacteristic->notify()) {
    Serial.println("[BLE] Notification failed");
  }
}

void sendError(const char* message) {
  StaticJsonDocument<160> document;
  document["type"] = "error";
  document["message"] = message;
  sendDocument(document);
}

void sendPong() {
  StaticJsonDocument<96> document;
  document["type"] = "pong";
  document["protocol"] = MINDMEOW_PROTOCOL_VERSION;
  sendDocument(document);
}

void sendTouch() {
  StaticJsonDocument<192> document;
  document["type"] = "touch";
  document["enabled"] = Sensor_isEnabled();
  document["touched"] = Sensor_isTouched();
  document["raw"] = Sensor_getRaw();
  document["baseline"] = Sensor_getBaseline();
  sendDocument(document);
}

void sendServo(const char* target, int reportedAngle = -1) {
  StaticJsonDocument<160> document;
  document["type"] = "servo";
  document["target"] = target;
  if (strcmp(target, "head") == 0) {
    document["enabled"] = Servo_isHeadEnabled();
    document["angle"] =
        reportedAngle >= 0 ? reportedAngle : Servo_getHeadAngle();
    document["moving"] = Servo_isHeadMoving();
  } else {
    document["enabled"] = Servo_isTailEnabled();
    document["angle"] =
        reportedAngle >= 0 ? reportedAngle : Servo_getTailAngle();
    document["moving"] = Servo_isTailMoving();
  }
  sendDocument(document);
}

void sendEyes() {
  StaticJsonDocument<144> document;
  document["type"] = "eyes";
  document["available"] = Eyes_isReady();
  document["enabled"] = Eyes_isEnabled();
  document["mode"] = Eyes_getMode();
  sendDocument(document);
}

void sendStatus() {
  StaticJsonDocument<512> document;
  document["type"] = "status";
  document["touchEnabled"] = Sensor_isEnabled();
  document["touched"] = Sensor_isTouched();
  document["touchRaw"] = Sensor_getRaw();
  document["touchBaseline"] = Sensor_getBaseline();
  document["headEnabled"] = Servo_isHeadEnabled();
  document["tailEnabled"] = Servo_isTailEnabled();
  document["headAngle"] = Servo_getHeadAngle();
  document["tailAngle"] = Servo_getTailAngle();
  document["eyesAvailable"] = Eyes_isReady();
  document["eyesEnabled"] = Eyes_isEnabled();
  document["eyeMode"] = Eyes_getMode();
  sendDocument(document);
}

void handleServo(JsonDocument& document) {
  const char* target = document["target"] | "";
  const bool isHead = strcmp(target, "head") == 0;
  const bool isTail = strcmp(target, "tail") == 0;
  if (!isHead && !isTail) {
    sendError("servo_target_invalid");
    return;
  }

  if (document.containsKey("enabled")) {
    if (!document["enabled"].is<bool>()) {
      sendError("servo_enabled_invalid");
      return;
    }
    const bool enabled = document["enabled"].as<bool>();
    const bool ok = isHead ? Servo_setHeadEnabled(enabled)
                           : Servo_setTailEnabled(enabled);
    if (!ok) {
      sendError("servo_attach_failed");
      return;
    }
    sendServo(target);
    return;
  }

  if (document.containsKey("angle")) {
    if (!document["angle"].is<int>()) {
      sendError("servo_angle_invalid");
      return;
    }
    const int angle = document["angle"].as<int>();
    const int minimum = isHead ? HEAD_MIN_ANGLE : TAIL_MIN_ANGLE;
    const int maximum = isHead ? HEAD_MAX_ANGLE : TAIL_MAX_ANGLE;
    if (angle < minimum || angle > maximum) {
      sendError("servo_angle_out_of_range");
      return;
    }
    if ((isHead && !Servo_isHeadEnabled()) ||
        (isTail && !Servo_isTailEnabled())) {
      sendError("servo_disabled");
      return;
    }
    const bool ok = isHead ? Servo_setHeadAngle(angle)
                           : Servo_setTailAngle(angle);
    if (!ok) {
      sendError("servo_command_failed");
      return;
    }
    sendServo(target, angle);
    return;
  }

  const char* action = document["action"] | "";
  if (isTail && strcmp(action, "wag") == 0) {
    if (!Servo_startTailWag()) {
      sendError("tail_servo_disabled");
      return;
    }
    sendServo("tail");
    return;
  }

  sendError("servo_command_missing");
}

void handleEyes(JsonDocument& document) {
  if (document.containsKey("enabled")) {
    if (!document["enabled"].is<bool>()) {
      sendError("eyes_enabled_invalid");
      return;
    }
    if (!Eyes_setEnabled(document["enabled"].as<bool>())) {
      sendError("eyes_unavailable");
      return;
    }
    sendEyes();
    return;
  }

  const char* mode = document["mode"] | "";
  if (!Eyes_setMode(mode)) {
    sendError("eyes_mode_invalid_or_images_missing");
    return;
  }
  sendEyes();
}

void handleTouch(JsonDocument& document) {
  if (!document["enabled"].is<bool>()) {
    sendError("touch_enabled_invalid");
    return;
  }
  Sensor_setEnabled(document["enabled"].as<bool>());
  sendTouch();
  Sensor_clearTouchChanged();
}

void handleCommand(const char* json) {
  StaticJsonDocument<256> document;
  const DeserializationError error = deserializeJson(document, json);
  if (error) {
    sendError("invalid_json");
    return;
  }

  const char* type = document["type"] | "";
  Serial.printf("[BLE RX] %s\n", json);
  if (strcmp(type, "ping") == 0) {
    sendPong();
  } else if (strcmp(type, "status_get") == 0) {
    sendStatus();
  } else if (strcmp(type, "servo") == 0) {
    handleServo(document);
  } else if (strcmp(type, "eyes") == 0) {
    handleEyes(document);
  } else if (strcmp(type, "touch") == 0) {
    handleTouch(document);
  } else {
    sendError("command_type_unknown");
  }
}

class ServerCallbacks : public NimBLEServerCallbacks {
  void onConnect(NimBLEServer* server, NimBLEConnInfo& connInfo) override {
    connected = true;
    advertisingRestartPending = false;
    Serial.printf("[BLE] Connected handle=%u address=%s\n",
                  connInfo.getConnHandle(),
                  connInfo.getAddress().toString().c_str());
  }

  void onDisconnect(NimBLEServer* server, NimBLEConnInfo& connInfo,
                    int reason) override {
    connected = false;
    disconnectedAt = millis();
    advertisingRestartPending = true;
    Serial.printf("[BLE] Disconnected reason=%d\n", reason);
  }
};

class CommandCallbacks : public NimBLECharacteristicCallbacks {
  void onWrite(NimBLECharacteristic* characteristic,
               NimBLEConnInfo& connInfo) override {
    if (commandQueue == nullptr) return;
    const std::string value = characteristic->getValue();
    CommandPacket packet{};
    packet.truncated = value.length() >= sizeof(packet.json);
    const size_t copyLength =
        min(value.length(), static_cast<size_t>(sizeof(packet.json) - 1));
    memcpy(packet.json, value.data(), copyLength);
    packet.json[copyLength] = '\0';

    if (xQueueSend(commandQueue, &packet, 0) != pdTRUE) {
      commandOverflow = true;
    }
  }
};

ServerCallbacks serverCallbacks;
CommandCallbacks commandCallbacks;

void processCommandQueue() {
  if (commandOverflow) {
    commandOverflow = false;
    sendError("command_queue_full");
  }

  CommandPacket packet{};
  // Process all queued writes in their original order. Peripheral operations
  // happen only in loop(), never inside the NimBLE callback task.
  while (commandQueue != nullptr &&
         xQueueReceive(commandQueue, &packet, 0) == pdTRUE) {
    if (packet.truncated) {
      sendError("command_too_long");
    } else {
      handleCommand(packet.json);
    }
  }
}

void updateTouchNotification() {
  const uint32_t now = millis();
  const bool periodic = connected &&
                        now - lastTouchNotifyAt >= kTouchNotifyIntervalMs;
  if (!Sensor_touchChanged() && !periodic) return;
  lastTouchNotifyAt = now;
  sendTouch();
  Sensor_clearTouchChanged();
}

void restartAdvertisingIfNeeded() {
  if (!advertisingRestartPending || connected || bleAdvertising == nullptr) {
    return;
  }
  if (millis() - disconnectedAt < kAdvertisingRestartDelayMs) return;
  advertisingRestartPending = false;
  const bool started = bleAdvertising->start();
  Serial.printf("[BLE] Advertising restart: %s\n", started ? "OK" : "FAILED");
}
}  // namespace

void BLE_begin() {
  bleReady = false;
  connected = false;
  commandQueue = xQueueCreate(8, sizeof(CommandPacket));
  if (commandQueue == nullptr) {
    Serial.println("[BLE] Failed to create command queue");
    return;
  }

  NimBLEDevice::init(MINDMEOW_DEVICE_NAME);
  NimBLEDevice::setMTU(247);
  NimBLEDevice::setPower(ESP_PWR_LVL_P9);

  bleServer = NimBLEDevice::createServer();
  if (bleServer == nullptr) return;
  bleServer->setCallbacks(&serverCallbacks);

  NimBLEService* service = bleServer->createService(MINDMEOW_SERVICE_UUID);
  if (service == nullptr) return;

  commandCharacteristic = service->createCharacteristic(
      MINDMEOW_COMMAND_UUID,
      NIMBLE_PROPERTY::WRITE | NIMBLE_PROPERTY::WRITE_NR);
  eventCharacteristic = service->createCharacteristic(
      MINDMEOW_EVENT_UUID, NIMBLE_PROPERTY::READ | NIMBLE_PROPERTY::NOTIFY);
  if (commandCharacteristic == nullptr || eventCharacteristic == nullptr) {
    Serial.println("[BLE] Failed to create characteristics");
    return;
  }
  commandCharacteristic->setCallbacks(&commandCallbacks);
  sendStatus();

  if (!service->start()) {
    Serial.println("[BLE] Failed to start service");
    return;
  }

  bleAdvertising = NimBLEDevice::getAdvertising();
  if (bleAdvertising == nullptr) return;
  bleAdvertising->reset();
  bleAdvertising->enableScanResponse(true);
  bleAdvertising->setName(MINDMEOW_DEVICE_NAME);
  bleAdvertising->addServiceUUID(MINDMEOW_SERVICE_UUID);
  bleAdvertising->setMinInterval(160);
  bleAdvertising->setMaxInterval(240);
  if (!bleAdvertising->start()) {
    Serial.println("[BLE] Failed to start advertising");
    return;
  }

  bleReady = true;
  Serial.printf("[BLE] Ready name=%s address=%s\n", MINDMEOW_DEVICE_NAME,
                NimBLEDevice::getAddress().toString().c_str());
}

void BLE_update() {
  if (!bleReady) return;
  processCommandQueue();
  updateTouchNotification();
  restartAdvertisingIfNeeded();
}

bool BLE_isConnected() { return connected; }
bool BLE_isReady() { return bleReady; }
