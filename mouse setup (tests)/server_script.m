% Last modified on August 10, 2017 by Dima.

function server_script

    warning('off');
    
    IP_ADDRESS       = '169.254.209.8';
    CLIENT_PORT      = 9091;
    SERVER_PORT      = 9090;
    BUFFER_SIZE      = 1024;
    
    LOAD_STIMULI     = 'load_stimuli';
    CONNECTED        = 'connected';    
    EXIT_TEST        = 'exit_test';
    STOP_SERVER      = 'stop_server';
    
    DELIMITER        = ';';
	PRIMARY_SCREEN   = 0;
    BACKGROUND_COLOR = 128;
    
    global udp_object;
    global stimuli;
    
    stimuli = {};
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if establish_connection(IP_ADDRESS, CLIENT_PORT, BUFFER_SIZE, SERVER_PORT)
        return;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    while true
        
        msg = fscanf(udp_object, '%s');
        
        switch msg 
            
            case CONNECTED                
                window_pointer = set_screen(BACKGROUND_COLOR, PRIMARY_SCREEN);
                if isempty(window_pointer)
                    exit_test;
                    break;
                end
                
            case LOAD_STIMULI
                try
                    filenames = fscanf(udp_object, '%s');
                    filenames = regexp(filenames, DELIMITER, 'split');
                    for counter = 1:length(filenames)
                        stimuli{counter} = imread(filenames{counter});
                        stimuli{counter} = Screen('MakeTexture', window_pointer, stimuli{counter});
                    end
                catch err
                    fprintf('Failed to upload stimuli into the memory.\n');
                    exit_test;
                end
                
            case EXIT_TEST
                exit_test;
                
            case STOP_SERVER
                exit_test;
                break;
                
            otherwise
                try
                    eval(msg);
                catch err
                    fprintf('Failed to execute a command string.\n');
                end
                
        end
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    close_connection;
    
    warning('on');
    
end

function exit_code = establish_connection(ip_address, client_port, buffer_size, server_port)

    global udp_object;
    
    % Denotes a successfully established connection. Otherwise, 1. 
    exit_code = 0;
    
    try       
        
        delete(instrfindall);
        udp_object = udp(ip_address, client_port, 'LocalPort', server_port); 
        udp_object.InputBufferSize = buffer_size;
        udp_object.InputDatagramPacketSize = buffer_size;
        fopen(udp_object);        
        fprintf('Successfully established a connection.\n'); 
        
    catch err         
        
        exit_code = 1;
        close_connection;
        fprintf('Failed to establish a connection.\n');     
        
    end
    
end

function close_connection

    global udp_object; 

    try 
           
        fclose(udp_object);
        delete(udp_object);
        fprintf('Successfully closed the connection.\n');
        
    catch err
        
        fprintf('Failed to close the connection.\n'); 
        
    end
    
end

function window_pointer = set_screen(background_color, primary_screen)
    
    window_pointer = [];
    
    try 
        
        window_pointer = Screen('OpenWindow', primary_screen);
        Screen('FillRect', window_pointer, background_color);
        Screen('Flip', window_pointer);
        HideCursor();
    
    catch err
        
        fprintf('Failed to set up a screen.\n');
        
    end

end

function exit_test

    try
        
        Screen('CloseAll');
        close all;
        
    catch err
        
        fprintf('Failed to clear the screen.\n');
        
    end
    
end
