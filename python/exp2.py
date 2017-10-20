"""
__copyright__ = "Copyright (c) 2017 Dzmitry Kaliukhovich"
__author__ = "Dzmitry Kaliukhovich"
__email__ = "dzmitry.kaliukhovich@gmail.com"
__license__ = "Public Domain"
"""

import msvcrt
import time
import threading
from mcculw import ul
from mcculw.enums import DigitalPortType

class Experiment:
    
    # Time during which the valve is open and the animal receives water reward (in seconds).
    REWARD_DURATION = 0.010
    
    # DAQ board identifier in Windows.
    DAQ_BOARD_NUMBER = 0
    
    # DAQ board is made up of 2 banks of relays referred by DigitalPortType.FIRSTPORTCL
    # and DigitalPortType.FIRSTPORTCH, respectively. Each bank includes 4 separate
    # relays. This results in total in 8 relays. They could be referred by
    # the corresponding numeric identifiers spanning the range from 0 to 7. 
    RELAY_IDENTIFIER  = 2    
    RELAY_DESCRIPTORS = [(DigitalPortType.FIRSTPORTCL, 1), (DigitalPortType.FIRSTPORTCL, 2), (DigitalPortType.FIRSTPORTCL, 4), (DigitalPortType.FIRSTPORTCL, 8),
                         (DigitalPortType.FIRSTPORTCH, 1), (DigitalPortType.FIRSTPORTCH, 2), (DigitalPortType.FIRSTPORTCH, 4), (DigitalPortType.FIRSTPORTCH, 8)]
    
    def __init__(self):      
        
        # Selected bank of relays (one of the two, see above) and relay within it.
        self.selected_bank, self.selected_relay = type(self).RELAY_DESCRIPTORS[type(self).RELAY_IDENTIFIER] 
        
        self.trial_no = 0     

        self.start_new_trial = threading.Event()
        self.initiate_stim_presentation = threading.Event()
        self.stim_presentation_is_complete = threading.Event()
        self.reward_is_requested = threading.Event()
        self.reward_is_delivered = threading.Event()
        self.trial_is_completed = threading.Event()
        self.exit_program = threading.Event()
        
        self.locomotion_thread = threading.Thread(target = self.track_locomotion)
        self.reward_thread = threading.Thread(target = self.deliver_reward)
        self.stimuli_thread = threading.Thread(target = self.present_stimuli)

    def track_locomotion(self):
        
        while True:
                   
            # Wait until a new trial is initiated.
            self.start_new_trial.wait()
            
            # Initiate stimulus presentation.
            self.initiate_stim_presentation.set()
            
            # Stop the current thread when requested.
            if self.exit_program.is_set():
                self.reward_is_requested.set()
                break         
            
            # Wait until stimulus presentation is complete.
            self.stim_presentation_is_complete.wait()   
            self.stim_presentation_is_complete.clear()
            
            # Request reward delivery.
            self.reward_is_requested.set()  
            
            # Wait until reward delivery is completed.
            self.reward_is_delivered.wait()
            self.reward_is_delivered.clear()
            
            # Notify the other threads that the current trial is completed.
            self.start_new_trial.clear()            
            self.trial_is_completed.set()
    
    def present_stimuli(self):
        
        while True:
            
            # Wait until stimulus presentation is requested.
            self.initiate_stim_presentation.wait()
            
            # Stop the current thread when requested.
            if self.exit_program.is_set():
                break            
            
            # Present visual stimuli.
            time.sleep(0.3)
            
            # Notify the other threads that stimulus presentation is complete.
            self.initiate_stim_presentation.clear()            
            self.stim_presentation_is_complete.set()
            
    def deliver_reward(self):
        
        while True:
            
            # Wait until reward delivery is requested.
            self.reward_is_requested.wait()
            
            # Stop the current thread when requested.
            if self.exit_program.is_set():
                break            
            
            # Reward the animal.   
            try:
                
                # Open the valve(s) for a specified time.
                ul.d_out(type(self).DAQ_BOARD_NUMBER, self.selected_bank, self.selected_relay)
                time.sleep(type(self).REWARD_DURATION)
                
                # Close the valve(s).
                ul.d_out(type(self).DAQ_BOARD_NUMBER, self.selected_bank, 0)
                
            except Exception as err:
                
                print(err)
                
            finally:
                
                # Notify the other threads that reward delivery is completed.
                self.reward_is_requested.clear()
                self.reward_is_delivered.set()
            
    def run(self):
        
        # Start threads for (1) acquisition of the locomotion data, (2) reward
        # delivery and (3) stimulus presentation.
        self.locomotion_thread.start()            
        self.reward_thread.start()
        self.stimuli_thread.start()
            
        while True:
            
            # Initiate a new trial.
            self.start_new_trial.set()
            
            # Exit the program.
            if self.exit_program.is_set():
                break
            
            # Increment and display trial number.
            self.trial_no += 1
            print("Trial no. %03d" % self.trial_no)         
                     
            # Wait until the current trial is completed.
            self.trial_is_completed.wait()
            self.trial_is_completed.clear()
            
            # Use a keystroke as the condition to exit the program.
            if msvcrt.kbhit():
                self.exit_program.set()                      
    
if __name__ == "__main__":
    
    my_exp = Experiment()
    my_exp.run()