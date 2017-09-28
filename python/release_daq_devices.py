from mcculw import ul

# Maximum number of DAQ devices allowed to be registered in the system.
MAX_DEVICES = 100

for counter in range(MAX_DEVICES):
    ul.release_daq_device(counter)

print('All DAQ devices and resources associated with them have been released.')