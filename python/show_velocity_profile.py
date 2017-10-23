import matplotlib.pyplot as plt
import numpy as np
import sys

bins = list(np.arange(start = -5, stop = 180, step = 5))
error_marker = -1

def convert_to_float(single_string_value):
    
    global error_marker
    
    try:
        return float(single_string_value)
    except ValueError:
        return error_marker
    
try:
    
    with open(sys.argv[1]) as file:

        raw_text_lines = file.readlines()
        processed_text_lines = [single_string_value.strip() for single_string_value in raw_text_lines]
        velocity_profile = list(map(convert_to_float, processed_text_lines))
        
        incorrect_datapoints = list(filter(lambda x: x == error_marker, velocity_profile))
        n_incorrect = len(incorrect_datapoints)
        n_total = len(velocity_profile)
        print("Incorrect / Total datapoints = %d / %d" % (n_incorrect, n_total))
        
        plt.subplot(1, 2, 1)
        plt.plot(velocity_profile)
        plt.xlabel("datapoint #")
        plt.ylabel("velocity, cm/sec")
        plt.title("Velocity profile over time")
        
        plt.subplot(1, 2, 2)        
        plt.hist(velocity_profile, bins = bins, normed = True)
        plt.xlabel("velocity, cm/sec")
        plt.ylabel("relative frequency")
        plt.title("Velocity distribution (mean x median = %.3f x %.3f cm/sec)" % (np.mean(velocity_profile), np.median(velocity_profile)))
        
        plt.show()
    
except Exception as err:

    print("Error: Failed to retrieve the velocity data! " + err)
