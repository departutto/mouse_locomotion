import window_interface, relay_interface

if __name__ == '__main__':
    
    valve = relay_interface.USB_ERB08_single_port(board_num = 15)
    if not valve.is_created():
        print("Failed to access the valve.")
        
    app = window_interface.User_window(valve)
    app.mainloop()