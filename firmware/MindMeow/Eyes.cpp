#include "Eyes.h"
#include "Config.h"

#include <Adafruit_GC9A01A.h>
#include <Adafruit_GFX.h>
#include <SPI.h>
#include <SPIFFS.h>
#include <TJpg_Decoder.h>

namespace {
Adafruit_GC9A01A eyeLeft(&SPI, TFT_DC, TFT_CS_LEFT, -1);
Adafruit_GC9A01A eyeRight(&SPI, TFT_DC, TFT_CS_RIGHT, -1);

enum EyeTarget { kNoEye, kLeftEye, kRightEye };

bool eyesReady = false;
bool eyesEnabled = true;
bool spiffsReady = false;
bool modeChanged = true;
bool animationRunning = false;
EyeTarget targetEye = kNoEye;

char currentMode[16] = "idle";
const char* leftPrefix = "L-";
const char* rightPrefix = "R-";
int currentFrame = 1;
int firstFrame = 1;
int lastFrame = 1;
uint32_t frameInterval = 100;
uint32_t lastFrameAt = 0;

bool jpgOutput(int16_t x, int16_t y, uint16_t w, uint16_t h,
               uint16_t* bitmap) {
  if (x >= 240 || y >= 240) return false;
  if (x + w > 240) w = 240 - x;
  if (y + h > 240) h = 240 - y;

  if (targetEye == kLeftEye) {
    eyeLeft.drawRGBBitmap(x, y, bitmap, w, h);
  } else if (targetEye == kRightEye) {
    eyeRight.drawRGBBitmap(x, y, bitmap, w, h);
  }
  return true;
}

bool fileExists(const char* filename) {
  if (!spiffsReady || !SPIFFS.exists(filename)) {
    Serial.printf("[Eyes] Missing image: %s\n", filename);
    return false;
  }
  return true;
}

void makeFilename(char* output, size_t size, const char* prefix, int frame) {
  snprintf(output, size, "/%s%d.jpg", prefix, frame);
}

void startAnimation(const char* newLeftPrefix, const char* newRightPrefix,
                    int from, int to, uint32_t intervalMs) {
  leftPrefix = newLeftPrefix;
  rightPrefix = newRightPrefix;
  firstFrame = from;
  lastFrame = to;
  currentFrame = from;
  frameInterval = intervalMs;
  lastFrameAt = 0;
  animationRunning = true;
}

void fillBoth(uint16_t color) {
  eyeLeft.fillScreen(color);
  eyeRight.fillScreen(color);
}

void applyMode() {
  modeChanged = false;
  animationRunning = false;
  if (!eyesEnabled) {
    fillBoth(GC9A01A_BLACK);
    return;
  }

  if (strcmp(currentMode, "idle") == 0) {
    Eyes_showBoth("/L-2.jpg", "/R-20.jpg");
  } else if (strcmp(currentMode, "animation") == 0) {
    startAnimation("L-", "R-", 1, 20, 100);
  } else if (strcmp(currentMode, "heart") == 0) {
    startAnimation("H-", "H-", 1, 3, 140);
  } else if (strcmp(currentMode, "wink") == 0) {
    startAnimation("W-", "W-", 1, 4, 120);
  } else if (strcmp(currentMode, "red") == 0) {
    fillBoth(GC9A01A_RED);
  } else if (strcmp(currentMode, "green") == 0) {
    fillBoth(GC9A01A_GREEN);
  } else if (strcmp(currentMode, "blue") == 0) {
    fillBoth(GC9A01A_BLUE);
  }
}

void updateAnimation() {
  if (!animationRunning || !eyesEnabled) return;
  const uint32_t now = millis();
  if (lastFrameAt != 0 && now - lastFrameAt < frameInterval) return;
  lastFrameAt = now;

  char leftFile[24];
  char rightFile[24];
  makeFilename(leftFile, sizeof(leftFile), leftPrefix, currentFrame);
  makeFilename(rightFile, sizeof(rightFile), rightPrefix, currentFrame);
  Eyes_showBoth(leftFile, rightFile);

  ++currentFrame;
  if (currentFrame > lastFrame) currentFrame = firstFrame;
}

bool isImageMode(const char* mode) {
  return strcmp(mode, "idle") == 0 || strcmp(mode, "animation") == 0 ||
         strcmp(mode, "heart") == 0 || strcmp(mode, "wink") == 0;
}

bool isValidMode(const char* mode) {
  return isImageMode(mode) || strcmp(mode, "red") == 0 ||
         strcmp(mode, "green") == 0 || strcmp(mode, "blue") == 0;
}
}  // namespace

void Eyes_begin() {
  eyesReady = false;
  pinMode(TFT_CS_LEFT, OUTPUT);
  pinMode(TFT_CS_RIGHT, OUTPUT);
  digitalWrite(TFT_CS_LEFT, HIGH);
  digitalWrite(TFT_CS_RIGHT, HIGH);

  SPI.begin(TFT_SCLK, TFT_MISO, TFT_MOSI, -1);

  pinMode(TFT_RST, OUTPUT);
  digitalWrite(TFT_RST, HIGH);
  delay(100);
  digitalWrite(TFT_RST, LOW);
  delay(100);
  digitalWrite(TFT_RST, HIGH);
  delay(200);

  eyeLeft.begin();
  eyeLeft.setRotation(0);
  eyeRight.begin();
  eyeRight.setRotation(0);
  fillBoth(GC9A01A_BLACK);
  eyesReady = true;

  spiffsReady = SPIFFS.begin(false);
  if (spiffsReady) {
    TJpgDec.setJpgScale(1);
    TJpgDec.setSwapBytes(false);
    TJpgDec.setCallback(jpgOutput);
    Serial.println("[Eyes] TFT and SPIFFS ready");
  } else {
    Serial.println("[Eyes] TFT ready, SPIFFS unavailable; color tests still work");
  }

  modeChanged = true;
  applyMode();
}

void Eyes_update() {
  if (!eyesReady) return;
  if (modeChanged) applyMode();
  updateAnimation();
}

bool Eyes_setEnabled(bool enabled) {
  if (!eyesReady) return false;
  eyesEnabled = enabled;
  modeChanged = true;
  return true;
}

bool Eyes_setMode(const char* mode) {
  if (!eyesReady || mode == nullptr || !isValidMode(mode)) return false;
  if (isImageMode(mode) && !spiffsReady) return false;
  strlcpy(currentMode, mode, sizeof(currentMode));
  modeChanged = true;
  return true;
}

bool Eyes_isReady() { return eyesReady; }
bool Eyes_isEnabled() { return eyesEnabled; }
const char* Eyes_getMode() { return currentMode; }

void Eyes_showLeft(const char* filename) {
  if (!eyesReady || !eyesEnabled || !fileExists(filename)) return;
  targetEye = kLeftEye;
  const JRESULT result = TJpgDec.drawFsJpg(0, 0, filename);
  targetEye = kNoEye;
  if (result != JDR_OK) {
    Serial.printf("[Eyes] Left JPG error=%d file=%s\n",
                  static_cast<int>(result), filename);
  }
}

void Eyes_showRight(const char* filename) {
  if (!eyesReady || !eyesEnabled || !fileExists(filename)) return;
  targetEye = kRightEye;
  const JRESULT result = TJpgDec.drawFsJpg(0, 0, filename);
  targetEye = kNoEye;
  if (result != JDR_OK) {
    Serial.printf("[Eyes] Right JPG error=%d file=%s\n",
                  static_cast<int>(result), filename);
  }
}

void Eyes_showBoth(const char* leftFilename, const char* rightFilename) {
  Eyes_showLeft(leftFilename);
  Eyes_showRight(rightFilename);
}
