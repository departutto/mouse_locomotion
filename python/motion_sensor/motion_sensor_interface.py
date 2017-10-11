# To install pySerial library, consult the following resources:
# - GitHub repository: https://github.com/pyserial/pyserial/blob/master/documentation/pyserial.rst
# - Documentation: http://pyserial.readthedocs.io/en/latest/pyserial.html
import serial 

class motion_sensor_interface:    
    
    # Encoding that appears to be used for data trasmission between Arduino Due boards
    # and PCs running on Windows.
    CODEC_NAME = "cp1252"
    
    def __init__(self, name = "COM4"):
        try:
            # Connection parameters:
            # - data transmission rate = 9600 baud (bits per second);
            # - number of data bits = 8;
            # - no parity checking;
            # - no timeout for either a read or write operation;
            # - no inter-character timeout;
            # - no software flow control;
            # - no hardware flow control of either RTS/CTS or DSR/DTR;            
            # - no exclusive access mode.
            self.port = serial.Serial(name)
            
            # Discard the first acquired data block. The Arduino board transfers the 
            # motion sensor data continuously and independently of any other software
            # running on the client side. As a consequence, we may omit the start of  
            # a new transferred data block when opening the port. In most cases, this 
            # will result in that the first acquired block contains incomplete or
            # corrupted data.
            self.port.readline()
            
        except Exception as err:
            print(err)
    
    def __del__(self):
        self.port.close()
        
    def read_displacement(self):
        text_line = self.port.readline()
        value = text_line.decode(type(self).CODEC_NAME).strip()
        return value
