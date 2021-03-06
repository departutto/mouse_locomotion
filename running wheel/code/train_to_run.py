from mcculw import ul
from mcculw.enums import DigitalPortType
import motion_sensor as ms
import msvcrt
import time

# Port to which the motion sensor is connected to.
port_name = "COM4"

# Sampling period of the motion sensor, in seconds. 
sampling_period = 0.010

# DAQ board identifier in Windows.
daq_board_number = 0

# Velocity threshold to detect locomotion, centimeters/second.
locomotion_is_detected = 1.0

# Time interval of the continuous locomotion that is rewarded, seconds.
continuous_motion = 0.5

# Time interval during which the valve is open and the animal receives water reward, seconds.
reward_duration = 0.050

# DAQ board is made up of 2 banks of relays referred by DigitalPortType.FIRSTPORTCL
# and DigitalPortType.FIRSTPORTCH, respectively. Each bank includes 4 separate
# relays. This results in total in 8 relays. They could be referred by the 
# corresponding numeric identifiers spanning the range from 0 to 7.
relay_identifier = 4
relay_descriptors = [(DigitalPortType.FIRSTPORTCL, 1), (DigitalPortType.FIRSTPORTCL, 2), (DigitalPortType.FIRSTPORTCL, 4), (DigitalPortType.FIRSTPORTCL, 8),
                     (DigitalPortType.FIRSTPORTCH, 1), (DigitalPortType.FIRSTPORTCH, 2), (DigitalPortType.FIRSTPORTCH, 4), (DigitalPortType.FIRSTPORTCH, 8)]

# Selected bank of relays (one of the two, see above) and relay within it.
selected_bank, selected_relay = relay_descriptors[relay_identifier] 

# Total number of the rewards delivered to the animal.
n_rewards = 0

# Create a text file that will store the data generated by the motion sensor.  
# The file format is as follows: "year_month_day_time_hour_minutes.txt".
file_name = time.strftime("%Y_%m_%d_time_%H_%M.txt", time.localtime())
file_obj = open(file_name, "wt")

# Connect to the motion sensor.
sensor = ms.Motion_sensor(port_name)
if sensor.is_connected():
    print("Successfully connected to the motion sensor.")
else:
    print("Failed to connect to the motion sensor.")
    exit()
  
# Number of the consecutive velocity data points that exceed the locomotion threshold.
counter = 0

# Timestamp corresponding to the beginning of a training session.  
beginning_training_session = time.clock()

# Display time corresponding to the beginning of a training session.
print("Start time: " + time.strftime("%X", time.localtime()))

# Repeat unless interrupted by a keystroke.
while not msvcrt.kbhit():
    
    try:
        
        # Read-out the current velocity and save it into the file.
        velocity_string_repr = sensor.read_sensor_data()
        file_obj.write(velocity_string_repr + "\n")
        velocity_numeric_repr = float(velocity_string_repr)
        
    except ValueError as err:
        
        print("Error: Failed to convert %s into float." % velocity_string_repr)
        continue
    
    if abs(velocity_numeric_repr) > locomotion_is_detected:        
        counter += 1       
    else:
        counter = 0
    
    # Reward animal for continuous locomotion.
    if counter * sampling_period >= continuous_motion:
        
        try:
            
            # Open the valve(s) for a specified time.
            ul.d_out(daq_board_number, selected_bank, selected_relay)
            
            n_rewards += 1
            print("[%03d] Reward delivery for %.3f seconds." % (n_rewards, reward_duration))
            time.sleep(reward_duration)
                    
            # Close the valve(s).
            ul.d_out(daq_board_number, selected_bank, 0)
        
        except Exception as err:
        
            print("Error: Failed to deliver water reward.")
            print(err)
            
        finally:
        
            counter = 0        

# Close the file that stores the velocity data.
file_obj.close()

# Timestamp corresponding to the end of the training session.
end_training_session = time.clock()

# Display duration of the training session (in seconds).
session_duration = end_training_session - beginning_training_session
print("Session duration is %.3f seconds." % session_duration)
        
