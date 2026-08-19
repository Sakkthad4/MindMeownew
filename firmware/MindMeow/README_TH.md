# MindMeow ESP32-S3 firmware

Firmware นี้ทำงานร่วมกับหน้า Hardware Test ของแอป Flutter ผ่าน BLE ชื่อ `MINDMEOW_CAT` รายละเอียด protocol, GPIO, การต่อไฟ, ไลบรารี และขั้นตอน upload อยู่ที่ [`../../docs/ble_hardware_integration_th.md`](../../docs/ble_hardware_integration_th.md)

ไฟล์หลักแยกตามหน้าที่:

- `AUDY_S3.ino` เรียก initialize/update ของแต่ละระบบ
- `MindMeow.ino` เป็น entry file ว่างตามกฎชื่อ sketch ของ Arduino CLI/IDE
- `Config.h` เก็บ GPIO, ช่วงองศาที่ปลอดภัย และ BLE UUID
- `BLEControl.*` ดูแล service, command queue, JSON และ notification
- `Eyes.*` ดูแล TFT สองจอ, SPIFFS/JPEG, animation แบบไม่ block และสีทดสอบ
- `ServoControl.*` ดูแล head/tail enable, ช่วงองศา และ wag แบบไม่ block
- `Sensor.*` ดูแล touch GPIO 13, baseline, hysteresis และ debounce
- `data/` เก็บ JPEG 47 ไฟล์สำหรับดวงตา

LED และ Battery ไม่ถูก initialize หรือ update ใน firmware ชุดนี้ตามขอบเขตการทดสอบฮาร์ดแวร์ปัจจุบัน
