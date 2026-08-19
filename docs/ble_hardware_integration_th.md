# การเชื่อมต่อ MindMeow Flutter กับ ESP32-S3 ผ่าน BLE

เอกสารนี้อธิบายโค้ดใน branch `feature/ble-hardware-test` โดยใช้แอป Flutter เดิมเป็นฐาน และเก็บ firmware แยกไว้ที่ `firmware/MindMeow/` ไม่ได้นำโปรเจกต์ Flutter จาก ZIP มาทับแอปเดิม

## สิ่งที่เปลี่ยน

- เพิ่มปุ่มรูปบอร์ดใน AppBar ข้างปุ่มเพลงและการตั้งค่า เพื่อเปิดหน้า `Hardware Test`
- เพิ่มการ scan, แสดงรายการ, connect, disconnect, สถานะ, ชื่ออุปกรณ์, ping และข้อมูลรับ/ส่งล่าสุด
- เพิ่มการดูค่า touch แบบ `touched`, `raw` และ `baseline`
- เพิ่มการเปิด/ปิดและทดสอบตำแหน่งเซอร์โวหัวกับหาง รวมถึงคำสั่งสะบัดหาง
- เพิ่มการเปิด/ปิดและทดสอบดวงตาแบบภาพเคลื่อนไหวและสีเต็มจอ
- เปลี่ยนการสื่อสารกับหุ่นยนต์จาก MQTT เป็น BLE เนื่องจาก MQTT เดิมใช้เฉพาะงานหุ่นยนต์ และต้องพึ่ง broker ภายนอกที่กำหนด IP ไว้ตายตัว
- คงเกม, healthcare, Hive, กล้อง, เสียง, asset และ route อื่นของแอปไว้

## BLE protocol

อุปกรณ์โฆษณาชื่อ `MINDMEOW_CAT` และใช้ UUID ต่อไปนี้

| รายการ | UUID | ทิศทาง/Property |
|---|---|---|
| Service | `6E400001-B5A3-F393-E0A9-E50E24DCCA9E` | Primary service |
| Command | `6E400002-B5A3-F393-E0A9-E50E24DCCA9E` | Flutter → ESP32, Write/Write without response |
| Event | `6E400003-B5A3-F393-E0A9-E50E24DCCA9E` | ESP32 → Flutter, Read/Notify |

ข้อมูลเป็น UTF-8 JSON หนึ่ง object ต่อหนึ่ง BLE write/notify การเขียนจาก Flutter เข้าคิวตามลำดับ และฝั่ง ESP32 เก็บคำสั่งใน FreeRTOS queue ก่อนประมวลผลใน `loop()` จึงไม่สั่งจอหรือเซอร์โวจาก callback ของ BLE โดยตรง

ตัวอย่างคำสั่งจากแอป:

```json
{"type":"ping"}
{"type":"status_get"}
{"type":"touch","enabled":true}
{"type":"servo","target":"head","enabled":true}
{"type":"servo","target":"head","angle":90}
{"type":"servo","target":"tail","enabled":true}
{"type":"servo","target":"tail","angle":130}
{"type":"servo","target":"tail","action":"wag"}
{"type":"eyes","enabled":true}
{"type":"eyes","mode":"heart"}
```

ค่า `target` ต้องเป็น `head` หรือ `tail` เท่านั้น โหมดตาที่รองรับคือ `idle`, `animation`, `heart`, `wink`, `red`, `green` และ `blue`

ตัวอย่าง event จาก firmware:

```json
{"type":"pong","protocol":1}
{"type":"touch","enabled":true,"touched":false,"raw":43120,"baseline":44780}
{"type":"servo","target":"head","enabled":true,"angle":90,"moving":false}
{"type":"eyes","available":true,"enabled":true,"mode":"idle"}
{"type":"error","message":"servo_angle_out_of_range"}
```

คำสั่ง `status_get` ตอบสถานะ touch, servo ทั้งสองตัว และดวงตาใน event ชนิด `status` แอปจะ subscribe characteristic ก่อนส่ง `ping` และ `status_get` เมื่อ disconnect จะล้าง characteristic/subscription เดิม ส่วน firmware จะกลับมา advertise อีกครั้งโดยอัตโนมัติ ผู้ใช้จึง scan และเชื่อมต่อใหม่ได้โดยไม่ต้อง reset บอร์ด

## GPIO สุดท้าย

| อุปกรณ์ | GPIO | หมายเหตุ |
|---|---:|---|
| Touch ลูบหัว | 13 | ใช้ `touchRead()` เพียง sensor เดียว |
| Signal เซอร์โวหัว MG996R | 15 | จำกัด 60–120°, เริ่ม 90° และยังไม่ attach ตอน boot |
| Signal เซอร์โวหาง MG90S | 16 | จำกัด 50–130°, เริ่ม 90° และยังไม่ attach ตอน boot |
| TFT SCLK | 12 | ใช้ร่วมกันสองจอ |
| TFT MOSI | 11 | ใช้ร่วมกันสองจอ |
| TFT DC | 10 | ใช้ร่วมกันสองจอ |
| TFT CS ซ้าย | 7 | แยก chip select |
| TFT CS ขวา | 8 | แยก chip select |
| TFT RST | 9 | ใช้ร่วมกันสองจอ |
| TFT MISO | ไม่ต่อ | จอทำงานแบบ write-only |

GPIO ทุกขาถูกกำหนดเพียงหน้าที่เดียวใน `Config.h` ไม่มีการอ่านปุ่มท้อง หู force sensor, LED หรือ battery ใน firmware ชุดนี้

## การต่อไฟและข้อควรระวัง

> **ห้ามจ่ายไฟให้ MG996R หรือ MG90S จากขา 3.3V ของ ESP32-S3**

ใช้แหล่งจ่ายภายนอก 5–6V ที่จ่ายกระแสพอสำหรับเซอร์โวทั้งสองตัว ต่อสาย GND ของแหล่งจ่ายเซอร์โวร่วมกับ GND ของ ESP32-S3 และต่อเฉพาะสาย signal ไป GPIO 15/16 แนะนำให้ใส่ capacitor ค่าอย่างน้อยประมาณ 470–1000 µF ใกล้จุดจ่ายไฟเซอร์โวเพื่อลดแรงดันตกและการ reset ของบอร์ด เมื่อทดสอบครั้งแรกให้ถอดแขนกลออกจากแกนหรือจัดพื้นที่ให้กลไกเคลื่อนได้โดยไม่ชน

จอ GC9A01A สองจอใช้ SCLK, MOSI, DC และ RST ร่วมกัน แต่ CS ต้องแยกเป็น GPIO 7 และ 8 ตรวจสอบแรงดัน logic/power ตามโมดูลจอที่ใช้จริง

## ไลบรารี Arduino

ติดตั้งผ่าน Arduino Library Manager:

- NimBLE-Arduino (API รุ่น 2.x)
- ArduinoJson
- ESP32Servo
- Adafruit GFX Library
- Adafruit GC9A01A
- TJpg_Decoder

เลือกบอร์ด ESP32-S3 ที่ตรงกับฮาร์ดแวร์ เปิด USB CDC ตามการต่อใช้งาน และเลือก Partition Scheme ที่มีพื้นที่ SPIFFS เพียงพอสำหรับภาพประมาณ 500 KB

## การอัปโหลด firmware และภาพตา

1. เปิด `firmware/MindMeow/AUDY_S3.ino` ใน Arduino IDE
2. ติดตั้ง ESP32 board package และไลบรารีข้างต้น
3. เลือกบอร์ด, port และ Partition Scheme ที่มี SPIFFS
4. กด Verify แล้ว Upload sketch
5. อัปโหลดโฟลเดอร์ `firmware/MindMeow/data/` ไปยัง SPIFFS ด้วย ESP32 Sketch Data Upload หรือเครื่องมือ filesystem upload ที่เข้ากับ ESP32 core รุ่นที่ติดตั้ง
6. เปิด Serial Monitor ที่ 115200 baud เพื่อตรวจ baseline touch, BLE address และข้อความ error

การ Upload sketch ตามปกติ **ไม่อัปโหลดรูปในโฟลเดอร์ `data`** ต้องทำขั้นตอน filesystem upload แยกต่างหาก ไฟล์ที่ต้องมีคือ `L-1..20.jpg`, `R-1..20.jpg`, `H-1..3.jpg` และ `W-1..4.jpg` รวม 47 ไฟล์ โหมด idle ใช้ `L-2.jpg` กับ `R-20.jpg`

## Touch calibration

ตอน boot firmware เฉลี่ยค่า 32 ตัวอย่างเป็น baseline จึงไม่ควรวางมือบนแผ่น touch ในช่วงเริ่มระบบ ค่าแตะใช้ threshold สัมพัทธ์จาก baseline (72%) ส่วนค่าปล่อยใช้ 82% เพื่อทำ hysteresis และต้องได้สถานะเดียวกันสามตัวอย่างติดกันก่อนเปลี่ยน state ขณะไม่ได้แตะ baseline จะปรับตามสภาพแวดล้อมอย่างช้า ๆ

ดู `raw` และ `baseline` ได้ทั้งใน Serial Monitor และหน้า Hardware Test หากเซนเซอร์ไวหรือช้าเกินไป ให้ปรับเปอร์เซ็นต์ใน `Sensor.cpp` จากผลวัดของฮาร์ดแวร์จริง ไม่ควรเปลี่ยนเป็น threshold คงที่โดยไม่เก็บค่าจากเครื่องจริงก่อน

## วิธีทดสอบจาก Flutter

1. รันแอปบน Android/iOS ที่รองรับ BLE และอนุญาต Bluetooth เมื่อระบบถาม
2. เปิดหน้าหลักและกดไอคอนบอร์ดใน AppBar
3. กด `Scan` เลือก `MINDMEOW_CAT` แล้วกด `Connect`
4. ตรวจว่าได้รับ pong และกด refresh เพื่ออ่านสถานะ
5. ลูบแผ่น touch และตรวจ `touched/raw/baseline`
6. เปิดเซอร์โวหัวก่อนทดสอบ 60/90/120° และเปิดเซอร์โวหางก่อนทดสอบ 50/90/130° หรือ Wag
7. เปิดดวงตาแล้วทดสอบแต่ละโหมด
8. กด Disconnect จากนั้น Scan/Connect ใหม่เพื่อทดสอบการ advertise ซ้ำ

บนเว็บ Web Bluetooth ขึ้นกับ browser และระบบปฏิบัติการ; Chrome บางแพลตฟอร์มรองรับ แต่การทดสอบฮาร์ดแวร์จริงแนะนำ Android หรือ iOS ส่วนเกมและหน้าปกติของแอปยังเปิดบนเว็บได้แม้เครื่องไม่รองรับ BLE
