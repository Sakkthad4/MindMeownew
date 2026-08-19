#pragma once

#include <Arduino.h>

void Servo_begin();
void Servo_update();

bool Servo_setHeadEnabled(bool enabled);
bool Servo_setTailEnabled(bool enabled);
bool Servo_setHeadAngle(int angle);
bool Servo_setTailAngle(int angle);
bool Servo_startTailWag();

bool Servo_isHeadEnabled();
bool Servo_isTailEnabled();
int Servo_getHeadAngle();
int Servo_getTailAngle();
bool Servo_isHeadMoving();
bool Servo_isTailMoving();
