from mcculw import ul
from mcculw.enums import InterfaceType
from mcculw.enums import DigitalPortType
from mcculw.ul import ULError

class USB_ERB08_single_port:
    """Measurement computing USB-ERB08.
    Number of relays: 8.
    Relay configuration: 2 banks of 4.
    Contact rating: 5 A @ 240 VAC or 28 VDC resistive.
    Contact resistance: 100 mOhm max (initial value).
    Operate time: 10 ms max.
    Release time: 5 ms max.
    External power input: +6.0 VDC to 12.5 VDC.
    """
    
    # Minimum and maximum allowed DAQ board identifiers.
    MIN_BOARD_NUM = 0
    MAX_BOARD_NUM = 99
    
    # Minimum and maximum allowed relay identifiers.
    MIN_RELAY_NUM = 0
    MAX_RELAY_NUM = 7
    
    # USB ERB08 has 2 banks, with each of them including 4 relays. The relay identifiers in the first bank span the range from 0
    # to 3, whereas the relays in the second bank are within the range from 4 to 7. 
    PORT_TYPE_DIV = 4
    
    # Logical "zero" for the selected relay.
    NULL_STATE = 0
    
    def __init__(self, board_num = 0, relay_num = 0):
        
        # Board identifier. Unique for each DAQ device and must be specified by the user. 
        self.board_num = board_num
        
        # Relay identifier.
        self.relay_num = relay_num
        
        # Indicate that initialization has not been completed yet.
        self.created = False
        
        try:
            
            # Check the type of provided input parameters and their range. 
            required = isinstance(self.board_num, int) and isinstance(self.relay_num, int)
            required = required and self.board_num >= self.MIN_BOARD_NUM and self.board_num <= self.MAX_BOARD_NUM
            required = required and self.relay_num >= self.MIN_RELAY_NUM and self.relay_num <= self.MAX_RELAY_NUM
            if not required:
                raise Exception('Wrong parameters have been provided.')
                
            # Relay state (0..1).
            self.curr_state = 0
            
            # Specify which bank of relays the specified relay identifier refers to.
            if self.relay_num < self.PORT_TYPE_DIV:
                self.port_type = DigitalPortType.FIRSTPORTCL
            else:
                self.port_type = DigitalPortType.FIRSTPORTCH
            
            # Logical "one" for the selected relay.
            self.one = 2 ** (self.relay_num % self.PORT_TYPE_DIV)
            
            # Detect all USB DAQ devices and return their descriptors.
            all_devices = ul.get_daq_device_inventory(InterfaceType.USB)
            # If no devices are detected, raise an error. Otherwise, use the first detected device.
            if all_devices:
                # Descriptor of the selected DAQ device.
                self.selected_device = all_devices[0]
                # Create a device object for the selected DAQ device and associate the board identifier with that object.
                ul.create_daq_device(self.board_num, self.selected_device)
                # Indicate that an instance of the class has been successfully initialized.
                self.created = True
            else:
                raise Exception('No USB DAQ device has been detected.')
                
        except Exception as err:
            print(err)
        
    def __del__(self):
        
        # Release all resources reserved for the selected DAQ device.
        ul.release_daq_device(self.board_num)
        
    def is_created(self):
        
        return self.created
    
    def set_state_to_one(self):
        
        try:
            if self.is_created():
                ul.d_out(self.board_num, self.port_type, self.one)
                self.curr_state = self.one
                
        except Exception as err:
            print(err)
    
    def set_state_to_zero(self):
        
        try:
            if self.is_created(): 
                ul.d_out(self.board_num, self.port_type, self.NULL_STATE)
                self.curr_state = self.NULL_STATE
                
        except Exception as err:
            print(err)
        
    def change_state(self):
        
        if self.is_created():
            if self.curr_state == self.NULL_STATE:
                self.set_state_to_one()
            else:
                self.set_state_to_zero()
