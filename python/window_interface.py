import tkinter, time, re

class Valve_controls(tkinter.Frame):
    
    # External padding on each side of the slave widgets.
    PADX = 4
    PADY = 4
    
    # Internal padding on each side of the slave widgets.
    IPADX = 4
    IPADY = 4
    
    # Minimum duration of reward delivery in milliseconds.
    MINIMUM_REWARD_DUR = 15
    
    def __init__(self, master = None, valve = None):
        tkinter.Frame.__init__(self, master)
        self.pack()
        self.create_widgets()
        self.valve = valve
        self.reward_dur = self.MINIMUM_REWARD_DUR
    
    def hot_keys(self, event_descriptor):
        if event_descriptor.keysym in {'o', 'O'}:
            self.open_valve()
        if event_descriptor.keysym in {'c', 'C'}:
            self.close_valve()
        if event_descriptor.keysym in {'r', 'R'}:
            self.deliver_reward()
        
    def open_valve(self):        
        print("Open valve")
        if self.valve and hasattr(self.valve, "set_state_to_one"):
            self.valve.set_state_to_one()    
        self.button_open_valve.focus_set()
    
    def close_valve(self):
        print("Close valve")
        if self.valve and hasattr(self.valve, "set_state_to_zero"):
            self.valve.set_state_to_zero()  
        self.button_close_valve.focus_set()
        
    def deliver_reward(self):  
        reward_str = self.entry_reward_dur.get()
        
        if reward_str.isdigit(): 
            reward_int = int(reward_str)
        else: 
            reward_int = 0            
        self.reward_dur = max([reward_int, self.MINIMUM_REWARD_DUR])
        
        self.entry_reward_dur.delete(0, len(reward_str))
        self.entry_reward_dur.insert(0, str(self.reward_dur))
            
        print('Deliver reward (%d ms)' % self.reward_dur)
        if self.valve:
            self.open_valve()
            time.sleep(self.reward_dur / 1000.0) # in seconds
            self.close_valve()
        
        self.button_deliver_reward.focus_set()
        
    def create_widgets(self):
        
        self.label_reward_dur = tkinter.Label(self)
        self.label_reward_dur["text"] = "Reward duration (ms):"
        self.label_reward_dur.pack(side = "left", ipadx = self.IPADX, ipady = self.IPADY, padx = self.PADX, pady = self.PADY)
        
        self.entry_reward_dur = tkinter.Entry(self)
        self.entry_reward_dur.insert(0, str(self.MINIMUM_REWARD_DUR))
        self.entry_reward_dur.pack(side = "left", ipadx = self.IPADX, ipady = self.IPADY, padx = self.PADX, pady = self.PADY)
        
        self.button_open_valve = tkinter.Button(self)
        self.button_open_valve["text"] = "Open valve"
        self.button_open_valve["command"] = self.open_valve
        self.button_open_valve.pack(side = "left",  ipadx = self.IPADX, ipady = self.IPADY, padx = self.PADX, pady = self.PADY)
        
        self.button_close_valve = tkinter.Button(self)
        self.button_close_valve["text"] = "Close valve"
        self.button_close_valve["command"] = self.close_valve
        self.button_close_valve.pack(side = "left", ipadx = self.IPADX, ipady = self.IPADY, padx = self.PADX, pady = self.PADY)
        
        self.button_deliver_reward = tkinter.Button(self)
        self.button_deliver_reward["text"] = "Deliver reward"
        self.button_deliver_reward["command"] = self.deliver_reward
        self.button_deliver_reward.pack(side = "left",  ipadx = self.IPADX, ipady = self.IPADY, padx = self.PADX, pady = self.PADY)
        
class User_window(tkinter.Tk):
    
    # Window title.
    TITLE = "Control GUI"
        
    def __init__(self, valve = None):
        tkinter.Tk.__init__(self)      
        
        controls = Valve_controls(self)        
        controls.pack()      
        self.bind('<Key-o>', controls.hot_keys)
        self.bind('<Key-O>', controls.hot_keys)
        self.bind('<Key-c>', controls.hot_keys)
        self.bind('<Key-C>', controls.hot_keys)
        self.bind('<Key-r>', controls.hot_keys)
        self.bind('<Key-R>', controls.hot_keys)
        
        self.title(self.TITLE)
        self.protocol("WM_DELETE_WINDOW", self.on_exit)        
        self.valve = valve
    
    def on_exit(self):
        del self.valve
        self.destroy()      