#include <SPI.h>
#include <avr/pgmspace.h>

// Registers.
#define REG_Product_ID                           0x00
#define REG_Revision_ID                          0x01
#define REG_Motion                               0x02
#define REG_Delta_X_L                            0x03
#define REG_Delta_X_H                            0x04
#define REG_Delta_Y_L                            0x05
#define REG_Delta_Y_H                            0x06
#define REG_SQUAL                                0x07
#define REG_Pixel_Sum                            0x08
#define REG_Maximum_Pixel                        0x09
#define REG_Minimum_Pixel                        0x0a
#define REG_Shutter_Lower                        0x0b
#define REG_Shutter_Upper                        0x0c
#define REG_Frame_Period_Lower                   0x0d
#define REG_Frame_Period_Upper                   0x0e
#define REG_Configuration_I                      0x0f
#define REG_Configuration_II                     0x10
#define REG_Frame_Capture                        0x12
#define REG_SROM_Enable                          0x13
#define REG_Run_Downshift                        0x14
#define REG_Rest1_Rate                           0x15
#define REG_Rest1_Downshift                      0x16
#define REG_Rest2_Rate                           0x17
#define REG_Rest2_Downshift                      0x18
#define REG_Rest3_Rate                           0x19
#define REG_Frame_Period_Max_Bound_Lower         0x1a
#define REG_Frame_Period_Max_Bound_Upper         0x1b
#define REG_Frame_Period_Min_Bound_Lower         0x1c
#define REG_Frame_Period_Min_Bound_Upper         0x1d
#define REG_Shutter_Max_Bound_Lower              0x1e
#define REG_Shutter_Max_Bound_Upper              0x1f
#define REG_LASER_CTRL0                          0x20
#define REG_Observation                          0x24
#define REG_Data_Out_Lower                       0x25
#define REG_Data_Out_Upper                       0x26
#define REG_SROM_ID                              0x2a
#define REG_Lift_Detection_Thr                   0x2e
#define REG_Configuration_V                      0x2f
#define REG_Configuration_IV                     0x39
#define REG_Power_Up_Reset                       0x3a
#define REG_Shutdown                             0x3b
#define REG_Inverse_Product_ID                   0x3f
#define REG_Motion_Burst                         0x50
#define REG_SROM_Load_Burst                      0x62
#define REG_Pixel_Burst                          0x64

extern const unsigned short firmware_length;
extern prog_uchar firmware_data[];

// Resolution along the x- and y-axes. The approximate resolution value for each register
// setting can be calculated using the following formula. Each bit change is ~200 cpi (counts
// per inch). The maximum write value is 0x29 (41 decimal) that is 8200 cpi. For example:
// ------------------------------------------------------------------
// Configuration value | Approximate resolution (cpi) | Description |
// ------------------------------------------------------------------
// 0x01                | 200                          | minimum     |
// 0x09                | 1800                         | default     |
// 0x24                | 7200                         |             |
// 0x29                | 8200                         | maximum     |
// ------------------------------------------------------------------
const byte CPI = 1;

// Sampling period for the motion sensor (in milliseconds).
const int PERIOD = 10; 

// Speed of the motion sensor relative to surface in cm/sec.
float speed;

// Sensitivity to the lift-off distance. Only lower 5 bits can be used (max value 31 decimal).
// Configures the lift detection from the nominal Z-height of 2.4 mm of navigation system
// when ADNS-9800 sensor is coupled with ADNS-6190-002 lens. Higher value will result in higher
// lift detection. Different surfaces will have different lift detection values with the same 
// setting due to different surface characteristic.
const byte LDT = 31; 

// Pin number on the Arduino board to which the motion sensor is connected to.
const int SENSOR_PIN = 10;

// Displacement of the motion sensor relative to surface along the two axes (2 bytes per axis) combined.
byte xydat[4];

// References to the displacement data along each of the two axes separately.
int16_t* x = (int16_t*) &xydat[0];
int16_t* y = (int16_t*) &xydat[2];

// Timestamps for the current and preceeding retrievals of the displacement data as well as the difference
// between them. 
unsigned long current_time;
unsigned long previous_time;
unsigned long time_difference;

//-----------------------------------------------------------------------------------------------------------

void setup() {
  // Opens a serial port and sets the data transmission rate at 9600 bits per second (bps).
  // One of the listed rates could be potentially used instead: 300, 600, 1200, 2400, 4800, 9600,  
  // 14400, 19200, 28800, 38400, 57600 or 115200 bps. The other parameters for data transmission 
  // are set by default (8 data bits, no parity, one stop bit).
  Serial.begin(9600);

  // Configures "SENSOR_PIN" as output.
  pinMode (SENSOR_PIN, OUTPUT);

  // Initializes the SPI bus by setting SCK, MOSI and SS to outputs by pulling SCK and MOSI low and SS high.
  SPI.begin();

  // Sets the SPI data mode: that is, clock polarity and phase.
  // SPI_MODE3: clock polarity (CPOL/CKP) = 1, clock phase (CPHA) = 1, clock edge (CKE/NCPHA) = 0.
  // More information on serial peripheral interface bus can be found at the following link:
  // https://en.wikipedia.org/wiki/Serial_Peripheral_Interface_Bus
  SPI.setDataMode(SPI_MODE3);

  // Sets the order of the bits shifted out of and into the SPI bus. 
  // Available options: LSBFIRST - least significant bit first, MSBFIRST - most significant bit first.
  SPI.setBitOrder(MSBFIRST);

  // Sets the SPI clock divider relative to the system clock. On the Arduino Due, the system clock
  // can be divided by values from 1 to 255. 
  SPI.setClockDivider(4);

  performStartup();  
  delay(1000); // milliseconds

  // Configures the motion sensor.
  adns_write_reg(REG_Configuration_I, CPI);
  adns_write_reg(REG_Lift_Detection_Thr, LDT);

  previous_time = millis();
}

//-----------------------------------------------------------------------------------------------------------
// Writes a "HIGH" or a "LOW" value to "SENSOR_PIN", with these values corresponding to the voltage set at 5V
// (or 3.3V on 3.3V boards) and 0V (ground), respectively.
//-----------------------------------------------------------------------------------------------------------

void adns_com_begin(){
  digitalWrite(SENSOR_PIN, LOW);
}

void adns_com_end(){
  digitalWrite(SENSOR_PIN, HIGH);
}

//-----------------------------------------------------------------------------------------------------------

byte adns_read_reg(byte reg_addr){
  adns_com_begin();
  
  // Sends address of the register, with MSBit = 0 indicating that it is a read operation.
  SPI.transfer(reg_addr & 0x7f); // 0x7f = 0b01111111
  delayMicroseconds(100); // tSRAD
  
  // Reads data.
  byte data = SPI.transfer(0);

  // tSCLK-NCS for a read operation is 120 ns.
  delayMicroseconds(1); 
  
  adns_com_end();
  
  // tSRW/tSRR (= 20 us) minus tSCLK-NCS.
  delayMicroseconds(19); 

  return data;
}

//-----------------------------------------------------------------------------------------------------------

void adns_write_reg(byte reg_addr, byte data){
  adns_com_begin();
  
  // Sends address of the register, with MSBit = 1 indicating that it is a write operation.
  SPI.transfer(reg_addr | 0x80); // 0x80 = 0b10000000
  
  // Sends data.
  SPI.transfer(data);

  // tSCLK-NCS for a write operation.
  delayMicroseconds(20); 
  
  adns_com_end();

  // tSWW/tSWR (= 120 us) minus tSCLK-NCS. It could be shortened, but is looks like a safe lower bound.
  delayMicroseconds(100);  
}

//-----------------------------------------------------------------------------------------------------------

void adns_upload_firmware(){  
  // Sets the configuration_IV register in 3k firmware mode.
  adns_write_reg(REG_Configuration_IV, 0x02); // bit 1 = 1 for 3k mode, other bits are reserved 
  
  // Writes 0x1d in SROM_enable reg for initializing.
  adns_write_reg(REG_SROM_Enable, 0x1d); 
  
  // Waits for more than one frame period. Assume that the frame rate is as low as 100fps, even if it should never be that low.
  delay(10);
  
  // Writes 0x18 to SROM_enable to start SROM download.
  adns_write_reg(REG_SROM_Enable, 0x18); 
  
  // Writes the SROM file (= firmware data).
  adns_com_begin();
  // Writes burst destination adress.
  SPI.transfer(REG_SROM_Load_Burst | 0x80); 
  delayMicroseconds(15);
  
  // Sends all bytes of the firmware.
  unsigned char c;
  for(int i = 0; i < firmware_length; i++) { 
    c = (unsigned char) pgm_read_byte(firmware_data + i);
    SPI.transfer(c);
    delayMicroseconds(15);
  }
  adns_com_end();
}

//-----------------------------------------------------------------------------------------------------------

void performStartup(void){
  // Ensures that the serial port is reset.
  adns_com_end(); 
  adns_com_begin(); 
  adns_com_end();

  // Forces reset and waits for reboot.
  adns_write_reg(REG_Power_Up_Reset, 0x5a); 
  delay(100); // milliseconds
  
  // Reads registers 0x02 to 0x06 (and discards the data)
  adns_read_reg(REG_Motion);
  adns_read_reg(REG_Delta_X_L);
  adns_read_reg(REG_Delta_X_H);
  adns_read_reg(REG_Delta_Y_L);
  adns_read_reg(REG_Delta_Y_H);
  
  // Uploads the firmware.
  adns_upload_firmware();
  delay(50); // milliseconds
  
  // Turns on the motion sensor in pulsed (not continious!) mode.
  byte laser_ctrl0 = adns_read_reg(REG_LASER_CTRL0);
  adns_write_reg(REG_LASER_CTRL0, laser_ctrl0 & 0xf0); // 0xf0 = 0b11110000
  delay(1); // milliseconds
}

//-----------------------------------------------------------------------------------------------------------

void loop() {
  // Reads the displacement data from the motion sensor.
  digitalWrite(SENSOR_PIN, LOW);
  xydat[0] = (byte) adns_read_reg(REG_Delta_X_L);
  xydat[1] = (byte) adns_read_reg(REG_Delta_X_H);    
  xydat[2] = (byte) adns_read_reg(REG_Delta_Y_L);
  xydat[3] = (byte) adns_read_reg(REG_Delta_Y_H); 
  digitalWrite(SENSOR_PIN, HIGH); 
  
  current_time = millis();
  time_difference = current_time - previous_time; // milliseconds
  speed = (2.54 / (CPI * 200)) * sqrt( (*x) * (*x) + (*y) * (*y) ) / (time_difference / 1000.0); // cm/sec
  
  if (time_difference != PERIOD) 
    speed = -1 * speed;
    
  Serial.println(speed, 1);
  
  previous_time = current_time;
  delay(PERIOD);
}

//-----------------------------------------------------------------------------------------------------------

