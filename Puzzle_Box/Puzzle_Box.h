


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
void doMainStage();
void doButtonStage();
void doUpdateDistance();
void doCheckOverrideSerial();
void doCheckAccess();
void PowerOff();
float toRandomUnit(int choice, float dist);

/* Fixed values should not need changing */
static const int DEF_ATTEMPT_MAX = 50;
static const int EEPROM_OFFSET = 100;

/* Program Stage Constants */
static const int MAIN_STAGE = 1;
static const int BUTTON_STAGE = 2;

/* Eye Animation Steps (12 step program) */
static const int eyeAnimationSteps[] = { 0, -1, -2, -2, -2, -1, 0, 1, 2, 2, 2, 1, 0 };
static const int MAX_EYE_STEPS = 13;


/* OLD CONSTANTS */

/* These values should be adjusted according to your needs */
static const int CLOSED_ANGLE = 80; // degrees
static const int OPEN_ANGLE = 180; // degrees
static const float DEST_LATITUDE = 47.512157;
static const float DEST_LONGITUDE = -119.498119;
static const int RADIUS = 5; // meters


