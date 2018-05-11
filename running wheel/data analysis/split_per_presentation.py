import sys, matplotlib.pyplot as plt

# Indicates a failure in signal sampling occurred on the Arduino Due board (see motion_sensor.ino).
SAMPLING_ERROR = -1234.5

# Maximum duration of a stimulus presentation, data points.
MAX_STIM_DURATION = 30 # x 10 msec/point = 300 msec

# Number of data points before and after each photocell event to be added. 
N_POINTS = 90

# Velocity signal.
data = []

###############################################################################

# Convert a string into a number.
def convert_to_float(x):
    try: 
        return float(x)
    except: 
        return None

###############################################################################

# Quit if no data file is provided.
if (len(sys.argv) > 1):
    filename = sys.argv[1]
    print('Filename = %s' % filename)
else:
    exit()

###############################################################################

try:
    raw_data = open(filename, 'rt')
    trial_data = open(filename + '.m', 'wt')
    
    # Read the raw velocity signal from a file.
    for line in raw_data:
        data.append(convert_to_float(line))     
    
    # Detect data points in the signal that are corrupted either due to a failure in signal sampling or numeric conversion. 
    corrupted = list(filter(lambda x: x == SAMPLING_ERROR or x is None, data))
    print('N(data points) = %d' % len(data))
    print('N(corrupted) = %d' % len(corrupted))

    # Detect photocell events per stimulus presentation.
    indices = [i for i in range(1, len(data)) if data[i - 1] is not None and data[i] is not None and data[i - 1] >= 0.0 and data[i] < 0]
    photocell_events = [(onset, offset) for onset, offset in zip(indices, indices[1:]) if offset - onset <= MAX_STIM_DURATION]
    
    # Convert negative velocity values associated with the photocell events into a proper format (see motion_sensor.ino).
    data = list(map(lambda x: x if x is None or x >= 0.0 else -1 * x - 1, data))
    
    # Save the velocity signal per stimulus presentation into a file.
    for counter, single_stim in enumerate(photocell_events):
        velocity_str = ' '.join(map(lambda x: str(x), data[single_stim[0] - N_POINTS:single_stim[1] + N_POINTS + 1]))
        trial_data.write('stimulus(%d).indices = [%d %d];\n' % (counter + 1, single_stim[0], single_stim[1]))        
        trial_data.write('stimulus(%d).velocity = [%s];\n' % (counter + 1, velocity_str))
        
except Exception as exc:
    print('An error occurred!\n' + exc)
    
finally:
    raw_data.close()
    trial_data.close()

# Compute duration of stimulus presentations and inter-stimulus intervals.
photocell_events = [photocell_event for single_stim in photocell_events for photocell_event in single_stim]
stim_durations = [photocell_events[counter] - photocell_events[counter - 1] for counter in range(1, len(photocell_events), 2)]
isi_durations = [photocell_events[counter] - photocell_events[counter - 1] for counter in range(2, len(photocell_events), 2)]

# Show duration of stimulus presentations and inter-stimulus intervals in a single plot.
fig = plt.figure()
plt.subplot(1, 2, 1), plt.plot(stim_durations)
plt.xlabel('stimulus presentation #'), plt.ylabel('duration, data points')
plt.title('N(data points ) = ' + str(len(stim_durations)))
plt.subplot(1, 2, 2), plt.plot(isi_durations)
plt.xlabel('inter-stimulus interval #'), plt.ylabel('duration, data points')
plt.title('N(data points ) = ' + str(len(isi_durations)))
plt.show()
fig.savefig(filename + '.pdf')
