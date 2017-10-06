from ctypes import byref, c_ulong, Structure, windll
import time

class Point(Structure):
        _fields_ = [("x", c_ulong), ("y", c_ulong)]
        
class Mouse:
            
    def __init__(self):
        windll.user32.SetProcessDPIAware()
        self.screen_width = windll.user32.GetSystemMetrics(0)
        self.screen_height = windll.user32.GetSystemMetrics(1)
        
        self.pt = Point()
        self.timestamp = time.clock()
        windll.user32.GetCursorPos(byref(self.pt))   
    
    def get_position(self):
        
        """
        Gets cursor position on the screen as well as the corresponding timestamp. 
        
        Input parameters.
        -----------------
        None. 
        
        Output parameters.
        ------------------
        (X, Y, timestamp) - Coordinates of the mouse cursor on the screen along the 
        horizontal and vertical axes, respectively, and the corresponding timestamp.
        In Windows, the timestamp corresponds to the wall-clock seconds elapsed from 
        the program launch.
        """
        
        self.timestamp = time.clock()
        windll.user32.GetCursorPos(byref(self.pt))   
        print(self.pt.x, self.pt.y)
        return self.pt.x, self.pt.y, self.timestamp

    def set_position(self, pt = None):
        
        """
        Moves the mouse cursor to a specified position on the screen.
        
        Input parameters.
        -----------------
        pt - Instance of class 'Point' specifying a new position of the mouse cursor
        on the screen. If omitted, the mouse cursor is moved to the previously acquired 
        position.
        
        Output parameters.
        ------------------
        None.
        """
        
        if pt and isinstance(pt, 'Point'):
            self.pt = pt
        
        self.timestamp = time.clock()
        windll.user32.SetCursorPos(self.pt.x, self.pt.y)