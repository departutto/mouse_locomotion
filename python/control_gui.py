import window_interface, relay_interface

if __name__ == '__main__':
    
    valve = relay_interface.USB_ERB08_single_port(relay_num = 7)
    app = window_interface.User_window(valve)
    app.mainloop()