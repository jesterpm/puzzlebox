/*
puzzle_box_sample.pde - Sample Arduino Puzzle Box sketch for MAKE.
COPYRIGHT (c) 2008-2011 MIKAL HART.  All Rights Reserved.
 
This software is licensed under the terms of the Creative
Commons "Attribution Non-Commercial Share Alike" license, version
3.0, which grants the limited right to use or modify it NON-
COMMERCIALLY, so long as appropriate credit is given and
derivative works are licensed under the IDENTICAL TERMS.  For
license details see

  http://creativecommons.org/licenses/by-nc-sa/3.0/
 
This source code is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 
This code is written to accompany the January, 2011 MAKE article 
entitled "Reverse Geocache Puzzle Box".
 
This sketch illustrates how one might implement a basic puzzle box 
that incorporates rudimentary aspects of the technology in Mikal 
Hart's Reverse Geocache(tm) puzzle.
 
"Reverse Geocache" is a trademark of Mikal Hart.

For supporting libraries and more information see 

  http://arduiniana.org.
*/

#include <PWMServo.h>
#include <NewSoftSerial.h>
#include <TinyGPS.h>
#include <EEPROM.h>
#include <LiquidCrystal.h>

void PowerOff();

#if 0 // Change this to 1 if you have the version 1.0 shield

/* Pin assignments for the version 1.0 shield */
static const int GPSrx = 2, GPStx = 3;
static const int LCD_Enable = 11, LCD_RS = 10, LCD_RW = 7;
static const int LCD_DB4 = 19, LCD_DB5 = 17, LCD_DB6 = 18, LCD_DB7 = 16;
static const int pololu_switch_off = 15; // Pololu switch control
static const int servo_control = 9;
static const int LED_pin = 12;

#else

/* Pin assignments for the version 1.1 shield */
static const int GPSrx = 4, GPStx = 3; // GPS
static const int LCD_Enable = 6, LCD_RS = 5, LCD_RW = 7; // LCD
static const int LCD_DB4 = 16, LCD_DB5 = 17, LCD_DB6 = 18, LCD_DB7 = 19;
static const int pololu_switch_off = 12; // Pololu switch control
static const int servo_control = 9; // Servo control
static const int LED_pin = 2; // The button LED

#endif

uint8_t eye1[8] = {
  B00000,
  B00000,
  B00000,
  B00000,
  B00000,
  B00001,
  B00011,
  B00011,
};
uint8_t eye2[8] = {
  B00000,
  B00111,
  B01111,
  B11000,
  B10001,
  B00011,
  B00111,
  B01110,
};
uint8_t eye3[8] = {
  B00000,
  B11100,
  B11110,
  B00011,
  B10001,
  B11000,
  B11100,
  B01110,
};
uint8_t eye4[8] = {
  B00000,
  B00000,
  B00000,
  B00000,
  B00000,
  B10000,
  B11000,
  B11000,
};
uint8_t eye5[8] = {
  B00011,
  B00011,
  B00001,
  B00000,
  B00000,
  B00000,
  B00000,
  B00000,
};
uint8_t eye6[8] = {
  B01110,
  B00111,
  B00011,
  B10001,
  B11000,
  B01111,
  B00111,
  B00000,
};
uint8_t eye7[8] = {
  B01110,
  B11100,
  B11000,
  B10001,
  B00011,
  B11110,
  B11100,
  B00000,
};
uint8_t eye8[8] = {
  B11000,
  B11000,
  B10000,
  B00000,
  B00000,
  B00000,
  B00000,
  B00000,
};


/* These values should be adjusted according to your needs */
static const int CLOSED_ANGLE = 80; // degrees
static const int OPEN_ANGLE = 180; // degrees
static const float DEST_LATITUDE = 47.512157;
static const float DEST_LONGITUDE = -119.498119;
static const int RADIUS = 5; // meters

/* Fixed values should not need changing */
static const int DEF_ATTEMPT_MAX = 50;
static const int EEPROM_OFFSET = 100;

/* Eye Animation Steps (12 step program) */
static const int eyeAnimationSteps[] = { 0, -1, -2, -2, -2, -1, 0, 1, 2, 2, 2, 1, 0 };
static const int MAX_EYE_STEPS = 13;

int currentEyeAnimationStep = 0;
long lastLoopTime = 0;

/* Loop Stage */
int loop_stage = 0;

/*

While waiting for a button press
1) Blink twice
2) wait 1 second

*/




/* The basic objects needed */
NewSoftSerial nss(GPSrx, GPStx);
LiquidCrystal lcd(LCD_RS, LCD_RW, LCD_Enable, LCD_DB4, LCD_DB5, LCD_DB6, LCD_DB7);
TinyGPS tinygps; 
int attempt_counter;
PWMServo servo;



/* A helper function to display messages of a specified duration */
void Msg(LiquidCrystal &lcd, const char *top, const char *bottom, unsigned long del)
{
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(top);
  lcd.setCursor(0, 1);
  lcd.print(bottom);
  delay(del);
}

// __|XX|__
// __|XX|__
// Location = 0 centers the eye.
void drawEye(int location)
{
  lcd.clear();

  location = location + 2;
  
  for (int i = 0; i < 4; i++) {
    lcd.setCursor(location + i, 0);
    lcd.write(i);
  }
  
  for (int i = 0; i < 4; i++) {
    lcd.setCursor(location + i, 1);
    lcd.write(i + 4);
  }
}

void stepEyeAnimation() {
  //if (currentEyeAnimationStep < 12) {
    drawEye(eyeAnimationSteps[currentEyeAnimationStep]);
    currentEyeAnimationStep++;
    currentEyeAnimationStep = currentEyeAnimationStep % 12;
  //}
}

void blinkEye() {
  // Eyes on
  digitalWrite(LED_pin, HIGH);
  delay(100);
  
  // Off
  lcd.noDisplay();
  digitalWrite(LED_pin, LOW);
  delay(100);
  
  // Back on
  lcd.display();
  digitalWrite(LED_pin, HIGH);
}

/* The Arduino setup() function */
void setup()
{
  /*Turn on switch LED*/
  pinMode(LED_pin, OUTPUT);
  digitalWrite(LED_pin,HIGH);
  
  /* attach servo motor */
  servo.attach(servo_control);

  /* establish a debug session with a host computer */
  Serial.begin(115200);

  /* establish communications with the GPS module */
  nss.begin(4800);

  /* establish communication with 8x2 LCD */
  lcd.createChar(0, eye1);
  lcd.createChar(1, eye2);
  lcd.createChar(2, eye3);
  lcd.createChar(3, eye4);
  lcd.createChar(4, eye5);
  lcd.createChar(5, eye6);
  lcd.createChar(6, eye7);
  lcd.createChar(7, eye8);
  lcd.begin(8, 2); // this for an 8x2 LCD -- adjust as needed 
  
  /* Make sure Pololu switch pin is OUTPUT and LOW */
  pinMode(pololu_switch_off, OUTPUT);
  digitalWrite(pololu_switch_off, LOW);
  
  /* make sure motorized latch is closed */
  servo.write(CLOSED_ANGLE); 
  
  /* read the attempt counter from the EEPROM */
  attempt_counter = EEPROM.read(EEPROM_OFFSET);
  if (attempt_counter == 0xFF) // brand new EEPROM?
    attempt_counter = 0;

  /* increment it with each run */
  ++attempt_counter;

  /* Greeting */
  Msg(lcd, "Hello", "Jesse!", 1500);
  Msg(lcd, "Welcome", "to your", 1500);
  Msg(lcd, "puzzle", "box!", 1500);

  /* Game over? */
  if (attempt_counter >= DEF_ATTEMPT_MAX)
  {
    Msg(lcd, "Sorry!", "No more", 2000);
    Msg(lcd, "attempts", "allowed!", 2000);
    PowerOff();
  }

  /* Print out the attempt counter */
  Msg(lcd, "This is", "attempt", 2000);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(attempt_counter);
  lcd.print(" of "); 
  lcd.print(DEF_ATTEMPT_MAX);
  delay(2000);

  /* Save the new attempt counter */
  EEPROM.write(EEPROM_OFFSET, attempt_counter);

  Msg(lcd, "Seeking", "Signal..", 0);
}

/* The Arduino loop() function */
void loop()
{
  
  if (millis() - lastLoopTime > 200) {
    stepEyeAnimation();
    lastLoopTime = millis();
  }  
  
  /* Has a valid NMEA sentence been parsed? */
  if (nss.available() && tinygps.encode(nss.read()))
  {
    float lat, lon;
    unsigned long fix_age;

    /* Have we established our location? */
    tinygps.f_get_position(&lat, &lon, &fix_age);
    if (fix_age != TinyGPS::GPS_INVALID_AGE)
    {
      /* Calculate the distance to the destination */
      float distance_meters = TinyGPS::distance_between(lat, lon, DEST_LATITUDE, DEST_LONGITUDE);

      /* Are we close?? */
      if (distance_meters <= RADIUS)
      {
        Msg(lcd, "Access", "granted!", 2000);
        servo.write(OPEN_ANGLE);
      }

      /* Nope.  Print the distance. */
      else
      {
        lcd.clear();
        lcd.setCursor(0, 0);
        lcd.print("Distance");
        lcd.setCursor(0, 1);
        if (distance_meters < 1000)
        {
          lcd.print((int)distance_meters);
          lcd.print(" m.");
        }

        else
        {
          lcd.print((int)(distance_meters / 1000));
          lcd.print(" km.");
        }
        delay(4000);
        Msg(lcd, "Access", "Denied!", 2000);
      }

      PowerOff();
    }
  }

  /* Turn off after 5 minutes */
  if (millis() >= 300000)
    PowerOff();
}

/* Called to shut off the system using the Pololu switch */
void PowerOff()
{
  Msg(lcd, "Powering", "Off!", 2000);
  lcd.clear(); 
  
  /*Turn off switch LED*/
  pinMode(LED_pin, OUTPUT);
  digitalWrite(LED_pin,LOW);
  
  /* Bring Pololu switch control pin HIGH to turn off */
  digitalWrite(pololu_switch_off, HIGH);

  /* This is the back door.  If we get here, then the battery power */
  /* is being bypassed by the USB port.  We'll wait a couple of */
  /* minutes and then grant access. */
  delay(120000);
  servo.write(OPEN_ANGLE); // and open the box 

  /* Reset the attempt counter */
  EEPROM.write(EEPROM_OFFSET, 0); 
  
  /* Leave the latch open for 10 seconds */
  delay(10000); 

  /* And then seal it back up */
  servo.write(CLOSED_ANGLE); 

  /* Exit the program for real */
  exit(1);
} 

