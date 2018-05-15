from mcculw import ul
from mcculw.enums import DigitalPortType
import motion_sensor as ms
import msvcrt
import time

# Port to which the motion sensor is connected to.
port_name = "COM3"

# Sampling period of the motion sensor, seconds. 
sampling_period = 0.010

# DAQ board identifier in Windows.
daq_board_number = 0

# Velocity threshold to detect locomotion, centimeters/second.
locomotion_is_detected = 1.0

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
  
# Timestamp corresponding to the beginning of a session.  
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

# Close the file that stores the velocity data.
file_obj.close()

# Timestamp corresponding to the end of the training session.
end_training_session = time.clock()

# Display duration of the training session (in seconds).
session_duration = end_training_session - beginning_training_session
print("Session duration is %.3f seconds." % session_duration)
        