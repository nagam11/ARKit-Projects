// Import libraries
#include <BLEDevice.h>
#include <BLEServer.h>
#include <BLEUtils.h>
#include <BLE2902.h>
#include <TaskScheduler.h>
#include <Arduino.h> 

// Define service and characteristics UUID
// See the following for generating UUIDs:
// https://www.uuidgenerator.net/
#define SERVICE_UUID              "9a8ca9ef-e43f-4157-9fee-c37a3d7dc12d"
#define GREEN_UUID                "e94f85c8-7f57-4dbd-b8d3-2b56e107ed60"
#define YELLOW_UUID               "a8985fda-51aa-4f19-a777-71cf52abba1e"
#define TOUCH_UUID                "beb5483e-36e1-4688-b7f5-ea07361b26a8"

// Device info 
#define DEVINFO_UUID              (uint16_t)0x180a
#define DEVINFO_MANUFACTURER_UUID (uint16_t)0x2a29
#define DEVINFO_NAME_UUID         (uint16_t)0x2a24
#define DEVINFO_SERIAL_UUID       (uint16_t)0x2a25
#define DEVICE_MANUFACTURER  "WROOM"
#define DEVICE_NAME    "My_ESP32"     

// Define LEDs and capacitive touch sensors pins
#define LED_G 13
#define LED_Y 12
#define Touch_G T0 // PIN 4 on ESP32
#define Touch_Y T2 // PIN 2 on ESP32

// Keep track of last states
bool green_active = false;
bool yellow_active = false;
// This variable serves as a threshold for avoiding multiple readings 
int repetitions = 0;
// 0 green , 1 for yellow
uint8_t touch = 2;

// BLE server
BLEServer* pServer = NULL;
bool deviceConnected = false;
bool oldDeviceConnected = false;

Scheduler scheduler;

BLECharacteristic *pCharGreen;
BLECharacteristic *pCharYellow;
BLECharacteristic *pTouch;

class MyServerCallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
      Serial.println("Connected");
      deviceConnected = true;
    };

    void onDisconnect(BLEServer* pServer) {
      Serial.println("Disconnected");
      deviceConnected = false;
    }
};

// Handle Requests for LED
class GreenCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();

      // 1 means a command was sent. Check what the last state was and update it.
      if (value.length()  == 1) {
        if (!green_active){
          uint8_t v = value[0];
          Serial.print("GREEN ON");
          digitalWrite(LED_G, HIGH);   // turn the LED on 
          green_active = true;
        } else {
          uint8_t v = value[0];
          Serial.print("YELLOW OFF");
          digitalWrite(LED_G, LOW);    // turn the LED off
          green_active = false;
        }        
      } else {
        Serial.println("Invalid data received");
      }
    }
};

class YellowCallbacks: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      std::string value = pCharacteristic->getValue();
      
      // 1 means a command was sent. Check what the last state was and update it.
      if (value.length()  == 1) {
        if (!yellow_active){
          uint8_t v = value[0];
          Serial.print("YELLOW ON");      
          digitalWrite(LED_Y, HIGH);   // turn the LED on 
          yellow_active = true;
        } else {
          uint8_t v = value[0];
          Serial.print("YELLOW OFF");
          digitalWrite(LED_Y, LOW);    // turn the LED off
          yellow_active = false;
        }        
      } else {
        Serial.println("Invalid data received");
      }
    }
};

void setup() {
  Serial.begin(115200);
  Serial.println("Starting...");

  //SETUP PINS
  pinMode(LED_G, OUTPUT);
  pinMode(LED_Y, OUTPUT);
  pinMode(Touch_G, INPUT);
  pinMode(Touch_Y, INPUT);

  String devName = "Marla_ESP32";
  String chipId = String((uint32_t)(ESP.getEfuseMac() >> 24), HEX);
  devName += '_';
  devName += chipId;

  // Create the BLE Device
  BLEDevice::init(devName.c_str());
  
  // Create the BLE Server
  pServer = BLEDevice::createServer();
  pServer->setCallbacks(new MyServerCallbacks());

   // Create the BLE Service
  BLEService *pService = pServer->createService(SERVICE_UUID);

  pCharGreen = pService->createCharacteristic(GREEN_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_WRITE);
  pCharGreen->setCallbacks(new GreenCallbacks());
  pCharGreen->addDescriptor(new BLE2902());

  pCharYellow = pService->createCharacteristic(YELLOW_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_WRITE);
  pCharYellow->setCallbacks(new YellowCallbacks());
  pCharYellow->addDescriptor(new BLE2902());

  // Create a BLE Characteristic
  pTouch = pService->createCharacteristic(TOUCH_UUID, BLECharacteristic::PROPERTY_READ | BLECharacteristic::PROPERTY_NOTIFY | BLECharacteristic::PROPERTY_WRITE | BLECharacteristic::PROPERTY_INDICATE);
  pTouch->addDescriptor(new BLE2902());
 
  // Start the service
  pService->start();

  pService = pServer->createService(DEVINFO_UUID);
  BLECharacteristic *pChar = pService->createCharacteristic(DEVINFO_MANUFACTURER_UUID, BLECharacteristic::PROPERTY_READ);
  pChar->setValue(DEVICE_MANUFACTURER);
  pChar = pService->createCharacteristic(DEVINFO_NAME_UUID, BLECharacteristic::PROPERTY_READ);
  pChar->setValue(DEVICE_NAME);
  pChar = pService->createCharacteristic(DEVINFO_SERIAL_UUID, BLECharacteristic::PROPERTY_READ);
  pChar->setValue(chipId.c_str());

  pService->start();

  // ----- Advertising

  BLEAdvertising *pAdvertising = pServer->getAdvertising();

  BLEAdvertisementData adv;
  adv.setName(devName.c_str());
  pAdvertising->setAdvertisementData(adv);

  BLEAdvertisementData adv2;
  adv2.setCompleteServices(BLEUUID(SERVICE_UUID));
  pAdvertising->setScanResponseData(adv2);

  pAdvertising->start();

  Serial.println("Ready");
  Serial.print("Device name: ");
  Serial.println(devName);
}

void loop() {
  scheduler.execute();

  // Notify on Toouch
    if (deviceConnected) {
        // Read 'Touch Values'
        int touchValue_green = touchRead(Touch_G);
        int touchValue_yellow = touchRead(Touch_Y);
        repetitions += 1;
        if (touchValue_green < 13 && touchValue_green > 4  && repetitions > 8 ){
          Serial.println(touchValue_green);
          Serial.println("TOUCH GREEN DETECTED");
          repetitions = 0;
          touch = 0;
          pTouch->setValue(&touch, 1);
          pTouch->notify();         
        }
        if (touchValue_yellow < 13 && touchValue_yellow > 4 && repetitions > 8 ){
          Serial.println(touchValue_yellow);
          Serial.println("TOUCH YELLOW DETECTED");
          repetitions = 0;   
          touch = 1;
          pTouch->setValue(&touch, 1);
          pTouch->notify();      
        } 
        touch = 2;
        delay(80); // bluetooth stack will go into congestion, if too many packets are sent
    }
   // disconnecting
    if (!deviceConnected && oldDeviceConnected) {
        delay(500); // give the bluetooth stack the chance to get things ready
        pServer->startAdvertising(); // restart advertising
        Serial.println("start advertising");
        oldDeviceConnected = deviceConnected;
    }
    // connecting
    if (deviceConnected && !oldDeviceConnected) {
        oldDeviceConnected = deviceConnected;
    }
}

