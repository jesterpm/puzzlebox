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

#include "Puzzle_Box.h"
#include "the_eye.h"
#include "quotes.h"

/* Hardware Objects */
NewSoftSerial nss(GPSrx, GPStx);
LiquidCrystal lcd(LCD_RS, LCD_RW, LCD_Enable, LCD_DB4, LCD_DB5, LCD_DB6, LCD_DB7);
TinyGPS tinygps;
PWMServo servo;

/* Running Information */
byte currentStage = MAIN_STAGE;
byte attempt_counter;
byte currentMessageId;
byte currentEyeAnimationStep = 0;
long lastLoopTime = 0;
long lastAniTime = 0;

float currentDistance = -1;
bool im_ready = false;
int currentUnit = 0;


/* The Arduino setup() function */
void setup() {
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
    currentMessageId = EEPROM.read(EEPROM_OFFSET + 1);
    currentStage = EEPROM.read(EEPROM_OFFSET + 2);

    if (attempt_counter == 0xFF) {
        // brand new EEPROM?
        attempt_counter = 0;
        currentMessageId = 0;
        currentStage = 0;
    }

    lastLoopTime = millis();

    pinMode(BUTTON_PIN, INPUT);
    digitalWrite(BUTTON_PIN, HIGH);

    randomSeed(analogRead(2));
}

/* The Arduino loop() function */
void loop() {
    // Check for a stage transition
    int buttonState = digitalRead(BUTTON_PIN);

    if (buttonState == LOW ) {
        currentStage++;

        // Find our stage
        switch (currentStage) {
            case MESSAGE:
                displayMessage();
                break;

            case LATLONG:
                doLatLong();
                break;

            case HEADING:
                doHeading();
                break;

            case EASTOF:
                doEastOf();
                break;

            case OPEN:
                servo.write(OPEN_ANGLE); // and open the box
                break;

            default:
                // Dunno
                break;
        }

    } else  {
        doIdle();
    }

    // Find the current distance just to be ready
    if (doUpdateDistance() && im_ready == false) {
        im_ready = true;
    }

    // Check for override login attempts
    doCheckOverrideSerial();

    /* Turn off after 5 minutes */
    if (millis() >= 300000) {
        PowerOff();
    }
}

/**
 * This is what we do while idle...
 */
void doIdle() {
    /* Timeline
     *    0  E On (500 ms)
     *  500  E Off (200 ms)
     *  700  E On (500 ms)
     * 1200  E off (200 ms)
     * 1400  E on (1600 ms)
     * 3000  Shift Anim. (200 ms/frame * 13 frames = 2600 ms)
     * 5600  On (3000 ms)
     * 8600  Back to the start
     */

    int delta = millis() - lastLoopTime;

    if (delta < 500) {
        // On
        toggleEye(true);

    } else if (delta < 700) {
        // Off
        toggleEye(false);

    } else if (delta < 1200) {
        // On
        toggleEye(true);

    } else if (delta < 1400) {
        // Off
        toggleEye(false);

    } else if (delta < 3000) {
        // On
        toggleEye(true);

    } else if (delta <= 5600) {
        // Shift Animation
        stepEyeAnimation();

    } else if (delta < 8600) {
        // Do nothing for now

    } else {
        // On
        toggleEye(true);

        // Reset timer
        lastLoopTime = millis();
    }
}

/**
 * This is what we do when the button has been pressed.
 */
void doLatLong() {
  // Plan to go back to the main stage
  currentStage = MAIN_STAGE;

    // Screen on please.
  toggleEye(true);

  /* increment it with each run */
  ++attempt_counter;

  // TODO: Witty Saying
    //showQuote(4);

  /* Greeting */
  Msg(lcd, "Hello", "Craig!", 1500);
  Msg(lcd, "Welcome", "to your", 1500);
  Msg(lcd, "puzzle", "box!", 1500);

  /* Game over? */
  // TODO: Oh no!
  if (attempt_counter >= DEF_ATTEMPT_MAX)
  {
    Msg(lcd, "Sorry!", "No more", 2000);
    Msg(lcd, "attempts", "allowed!", 2000);
    PowerOff();
  }

  /* Print out the attempt counter */
  Msg(lcd, "This is", "attempt", 1500);
  lcd.clear();
  lcd.setCursor(0, 0);
  lcd.print(attempt_counter);
  lcd.print(" of ");
  lcd.print(DEF_ATTEMPT_MAX);
  delay(2000);

  if (currentDistance == -1) {
      Msg(lcd, "Seeking", "Signal..", 0);
      long start = millis();
      while (!doUpdateDistance() && millis() - start < 10000);

      if (currentDistance == -1) {
          Msg(lcd, "No   :(", "Signal", 2000);
          attempt_counter--;
          return;
      }
  }

  /* Save the new attempt counter */
  EEPROM.write(EEPROM_OFFSET, attempt_counter);
  EEPROM.write(EEPROM_OFFSET + 1, currentMessageId);
  EEPROM.write(EEPROM_OFFSET + 2, currentStage);

  doCheckAccess();
}

void doHeading() {

}

void doEastOf() {

}

/**
 * This function updates the distance, if possible.
 *
 * Return true if it finished reading data.
 */
bool doUpdateDistance() {
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
      currentDistance = TinyGPS::distance_between(lat, lon, LATLONG_LATITUDE, LATLONG_LONGITUDE);
      return true;
    }
  }

  return false;
}

/**
 * This function checks for communication traffic from the usb serial port.
 */
void doCheckOverrideSerial() {

}

void doCheckAccess() {
  /* Are we close?? */
  if (currentDistance <= RADIUS)
  {
    Msg(lcd, "Access", "granted!", 2000);
    servo.write(OPEN_ANGLE);
  }

  /* Nope.  Print the distance. */
  else
  {
    // Get a random unit
    lcd.clear();
    lcd.setCursor(0, 0);
    lcd.print((long)toRandomUnit(currentUnit, currentDistance));
        lcd.setCursor(0, 1);
    lcd.print(getUnitLabel(currentUnit));

        currentUnit = (currentUnit + 1) % NUMBER_OF_UNITS;

    delay(4000);
    Msg(lcd, "Access", "Denied!", 2000);
  }
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
  EEPROM.write(EEPROM_OFFSET + 1, 0);
  EEPROM.write(EEPROM_OFFSET + 2, 0);

  /* Leave the latch open for 10 seconds */
  delay(10000);

  /* And then seal it back up */
  servo.write(CLOSED_ANGLE);

  /* Exit the program for real */
  exit(1);
}

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
  long delta = millis() - lastAniTime;

  if (delta >= 200) {
    drawEye(eyeAnimationSteps[currentEyeAnimationStep]);
    currentEyeAnimationStep++;
    currentEyeAnimationStep = currentEyeAnimationStep % 12;
    lastAniTime = millis();
  }
}

void toggleEye(bool on) {
    // Eyes on
    if (on) {
        lcd.display();
        digitalWrite(LED_pin, HIGH);

    } else {
      lcd.noDisplay();
      digitalWrite(LED_pin, LOW);
    }
}

/**
 * Convert the distance (m) to a particular unit.
 *
 */
float toRandomUnit(int choice, float dist) {
    switch (choice) {
        // meters
        case 0:
            return dist;

        // feet
        case 1:
            return dist * 3.2808;

        // cubits
        case 2:
            return dist * 2.18;

        // hands
        case 3:
            return dist * 9.84252;

        default:
            return -1;
    }
}

/**
 * Get the label for each unit.
 */
char* getUnitLabel(int choice) {
    switch (choice) {
        // meters
        case 0:
          return " m.";

        // feet
        case 1:
          return " ft.";

        // cubits
        case 2:
          return " cu.";

        // hands
        case 3:
          return " hh.";

        default:
          return " ?";
    }
}

void displayMessage() {
    int id = currentMessageId++;
    int pairs = messages[id].pairs;

    for (int i = 0; i < pairs; i++) {
        Msg(lcd,
            messages[id].lines[i].line1,
            messages[id].lines[i].line2,
            1000);
    }
}
