import sys, numpy as np

# Indicates a failure in signal sampling occurred on the Arduino Due board (see motion_sensor.ino).
SAMPLING_ERROR = -1234.5

# Velocity signal.
velocity = []

# Threshold to detect locomotion.
locomotion_thr = 1.0

# Convert a string into a number.
def convert_to_float(x):
    try: 
        return float(x)
    except: 
        return None

# Quit if no data files are provided.
if len(sys.argv) <= 1:
    exit()
 
# Read out the velocity signal from the list of provided files.
for filename in sys.argv[1:]:
    try:
        file_id = open(filename, 'r')
        for line in file_id:
            velocity.append(convert_to_float(line))
        print('Successfully processed: ' + filename)
        
    except:
        print('Failed to process: ' + filename)
        
    finally:
        file_id.close()

# Change the data points corrupted due to improper signal sampling by "None"-s. 
velocity = list(map(lambda x: None if x == SAMPLING_ERROR else x, velocity))

# Convert negative values associated with the photocell events into a proper format (see motion_sensor.ino).
velocity = list(map(lambda x: x if x is None or x >= 0.0 else -1 * x - 1, velocity))

# Data points associated with locomotion.
locomotion = list(filter(lambda x: x is not None and x >= locomotion_thr, velocity))

# Data points associated with stationary periods.
stationary = list(filter(lambda x: x is not None and x < locomotion_thr, velocity))

# Total number of the retrieved data points. 
n_total = len(velocity)

# Number of the retrieved data points that are in a proper numeric format. 
n_proper = len(locomotion) + len(stationary)

# Display statistics on mouse's locomotion.
print('Total number of the retrieved data points is %d.' % n_total)
print('Out of those, %d points are proper real numbers.' % n_proper)
print('We used %.2f cm/sec as the threshold to detect locomotion.' % locomotion_thr)
print('The number of data points above the threshold is %d (%.2f%%).' % (len(locomotion), len(locomotion) / n_proper * 100.0))
print('The number of data points below the threshold is %d (%.2f%%).' % (len(stationary), len(stationary) / n_proper * 100.0))
print('The average locomotion speed is %.2f cm/sec.' % np.mean(locomotion))
print('The median locomotion speed is %.2f cm/sec.' % np.median(locomotion))
print('The 25th-75th percentiles of the locomotion speed are %s cm/sec.' % np.percentile(locomotion, [25, 75]))
print('The standard deviation of the locomotion speed is %.2f cm/sec.' % np.std(locomotion))
print('The maximum locomotion speed detected is %.2f cm/sec.' % np.max(locomotion))
