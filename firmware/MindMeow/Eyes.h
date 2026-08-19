#pragma once

#include <Arduino.h>

void Eyes_begin();
void Eyes_update();

bool Eyes_setEnabled(bool enabled);
bool Eyes_setMode(const char* mode);
bool Eyes_isReady();
bool Eyes_isEnabled();
const char* Eyes_getMode();

void Eyes_showLeft(const char* filename);
void Eyes_showRight(const char* filename);
void Eyes_showBoth(const char* leftFilename, const char* rightFilename);
