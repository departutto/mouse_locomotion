import serial
import matplotlib.pyplot as plt

PORT_NAME    = "COM4"
N_DATAPOINTS = 400
ENCODING     = "cp1252"
ERROR_TAG    = -1

def read_data(port_name = PORT_NAME, n_datapoints = N_DATAPOINTS):
    try:
        ser_connection = serial.Serial(port_name)
        acquired_data  = []
        # (1) Time elapsed from the preceding data retrieval (ms) and (2) speed (cm/s).
        for counter in range(2 * n_datapoints):
            text_line = ser_connection.readline().decode(ENCODING).strip()
            acquired_data.append(text_line)
        ser_connection.close()
    except Exception as err:
        return err
    return acquired_data

def split_data(data):
    odd_positions  = data[1::2]
    even_positions = data[0::2]
    # Only non-negative real numbers are preserved. 
    is_feasible    = lambda x: x if x.replace('.', '', 1).isdigit() else ERROR_TAG
    return list(map(is_feasible, even_positions)), list(map(is_feasible, odd_positions))
  
def display_data(data, title):
    plt.figure()
    plt.plot(data, 'ko-')
    plt.xlabel('data point #')
    plt.ylabel('retrieved value') 
    plt.title('Retrieved data: ' + title)
    plt.show()
    
if __name__ == "__main__":
    try:
        data = read_data()
        even, odd = split_data(data)
        display_data(even, 'Even positions')
        display_data(odd, 'Odd positions')
    except Exception as err:
        print(err)
