#pragma once

#include <Arduino.h>

void Sensor_begin();
void Sensor_update();

void Sensor_setEnabled(bool enabled);
bool Sensor_isEnabled();
bool Sensor_isTouched();
uint32_t Sensor_getRaw();
uint32_t Sensor_getBaseline();
bool Sensor_touchChanged();
void Sensor_clearTouchChanged();
