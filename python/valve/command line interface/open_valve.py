from mcculw import ul
from mcculw.enums import DigitalPortType
import msvcrt
import sys

# Retrieve relay identifier from the command line input.
try:
    
    relay_identifier = int(sys.argv[1])
    if relay_identifier < 0 or relay_identifier > 7:
        raise ValueError()
        
except:
    
    print("Error: Failed to decipher relay identifier or its value is incorrect!")
    exit()

# DAQ board identifier in Windows.
daq_board_number = 0

# DAQ board is made up of 2 banks of relays referred by DigitalPortType.FIRSTPORTCL
# and DigitalPortType.FIRSTPORTCH, respectively. Each bank includes 4 separate
# relays. This results in total in 8 relays. They could be referred by the 
# corresponding numeric identifiers spanning the range from 0 to 7.
relay_descriptors = [(DigitalPortType.FIRSTPORTCL, 1), (DigitalPortType.FIRSTPORTCL, 2), (DigitalPortType.FIRSTPORTCL, 4), (DigitalPortType.FIRSTPORTCL, 8),
                     (DigitalPortType.FIRSTPORTCH, 1), (DigitalPortType.FIRSTPORTCH, 2), (DigitalPortType.FIRSTPORTCH, 4), (DigitalPortType.FIRSTPORTCH, 8)]

# Selected bank of relays (one of the two, see above) and relay within it.
selected_bank, selected_relay = relay_descriptors[relay_identifier] 

# Open the valve.
ul.d_out(daq_board_number, selected_bank, selected_relay)
            
# Repeat unless interrupted by a keystroke.
while not msvcrt.kbhit():
    pass

# Close the valve.
ul.d_out(daq_board_number, selected_bank, 0)
