#include "Config.h"
#include "Eyes.h"
#include "ServoControl.h"
#include "Sensor.h"
#include "BLEControl.h"

void setup() {
  Serial.begin(115200);
  delay(300);

  Serial.println();
  Serial.println("[MindMeow] Boot");

  Eyes_begin();
  Servo_begin();
  Sensor_begin();
  BLE_begin();

  Serial.println("[MindMeow] Ready");
}

void loop() {
  Sensor_update();
  BLE_update();
  Servo_update();
  Eyes_update();
}
