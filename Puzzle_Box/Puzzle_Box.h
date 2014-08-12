/* Pin assignments for the version 1.1 shield */
static const int GPSrx = 4, GPStx = 3; // GPS
static const int LCD_Enable = 6, LCD_RS = 5, LCD_RW = 7; // LCD
static const int LCD_DB4 = 16, LCD_DB5 = 17, LCD_DB6 = 18, LCD_DB7 = 19;
static const int pololu_switch_off = 12; // Pololu switch control
static const int servo_control = 9; // Servo control
static const int LED_pin = 2; // The button LED
static const int BUTTON_PIN = 1; // The pin for the button.

/* Function definitions */
void Msg(LiquidCrystal &lcd, const char *top, const char *bottom, unsigned long del);
void drawEye(int location);
void stepEyeAnimation();
void toggleEye(bool on);

void doIdle();
void displayMessage();
void doLatLong();
void doHeading();
void doEastOf();

bool doUpdateDistance();
void doCheckOverrideSerial();
void doCheckAccess();
void PowerOff();
float toRandomUnit(int choice, float dist);

float toRandomUnit(int choice, float dist);
char* getUnitLabel(int choice);

/* Fixed values should not need changing */
static const int DEF_ATTEMPT_MAX = 50;
static const int EEPROM_OFFSET = 100;

/* Program Stage Constants */
static const int MAIN_STAGE = 1;
static const int BUTTON_STAGE = 2;

static const char MESSAGE = 3;
static const char LATLONG = 4;
static const char HEADING = 5;
static const char EASTOF  = 6;
static const char OPEN    = 7;

static const byte STATES[] = {
        0,
        MESSAGE, // Daniel!? Is it you?
        MESSAGE, // Finally, you found me; Adventure time
        LATLONG,
        MESSAGE, // What's that?
        HEADING,
        MESSAGE, // Well that was fun, lets go back to camp
        EASTOF,
        MESSAGE, // Oh, btw, got you a gift
        OPEN
    };

// LATLONG
static const float LATLONG_LATITUDE = 46.09681;
static const float LATLONG_LONGITUDE = -121.65900;

// HEADING
// 46.092838, -121.649211
static const float HEADING_LATITUDE = 46.092838;
static const float HEADING_LONGITUDE = -121.649211;

// EASTOF
static const float EASTOF_LONGITUDE = -121.62730;

/* Random Units */
static const int NUMBER_OF_UNITS = 4;

/* Eye Animation Steps (12 step program) */
static const int eyeAnimationSteps[] = { 0, -1, -2, -2, -2, -1, 0, 1, 2, 2, 2, 1, 0 };
static const int MAX_EYE_STEPS = 13;


/* OLD CONSTANTS */

/* These values should be adjusted according to your needs */
static const int CLOSED_ANGLE = 80; // degrees
static const int OPEN_ANGLE = 200; // degrees
static const int RADIUS = 100; // meters
