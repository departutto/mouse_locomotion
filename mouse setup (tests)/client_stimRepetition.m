% Last modified on August 10, 2017 by Dima.

function client_stimRepetition
    
    % Command string per trial executed on the server side:
    %   param #1 - pointer to the screen for stimulus presentation;
    %   param #2 - stimulus condition;
    %   param #3 - duration of stimulus presentation, frames;
    %   param #4 - duration of inter-stimulus interval (ISI), frames;
    %   param #5 - color of the blank screen during ISI, unsigned byte;
    %   params #6 and 7 - coordinates of the uppermost left corner of the 
    %                     stimuli on the screen, unsigned bytes;
    %   params #8 and 9 - stimulus identifier;
    %   param #10 - time between the test stimulus offset and the trial end, frames.
    command_template = 'server_stimRepetition(window_pointer, %02d, 18, 18, 128, 361, 1, 1, 50, 60)';
    
    % Maximum duration of one trial, seconds.
    trial_duration = 2.3;
    
    % Experiment identifier.
    exp_id = 48;
    
    % Stimuli.
    filenames = {'.\set001\01.jpg;', '.\set001\02.jpg;', '.\set001\03.jpg;', '.\set001\04.jpg;', '.\set001\05.jpg;', ...
                 '.\set001\06.jpg;', '.\set001\07.jpg;', '.\set001\08.jpg;', '.\set001\09.jpg;', '.\set001\10.jpg;', ...
                 '.\set001\11.jpg;', '.\set001\12.jpg;', '.\set001\13.jpg;', '.\set001\14.jpg;', '.\set001\15.jpg;', ...
                 '.\set001\16.jpg;', '.\set001\17.jpg;', '.\set001\18.jpg;', '.\set001\19.jpg;', '.\set001\20.jpg;', ...
                 '.\set001\21.jpg;', '.\set001\22.jpg;', '.\set001\23.jpg;', '.\set001\24.jpg;', '.\set001\25.jpg;', ...
                 '.\set001\26.jpg;', '.\set001\27.jpg;', '.\set001\28.jpg;', '.\set001\29.jpg;', '.\set001\30.jpg;', ...
                 '.\set001\31.jpg;', '.\set001\32.jpg;', '.\set001\33.jpg;', '.\set001\34.jpg;', '.\set001\35.jpg;', ...
                 '.\set001\36.jpg;', '.\set001\37.jpg;', '.\set001\38.jpg;', '.\set001\39.jpg;', '.\set001\40.jpg;', ...
                 '.\set001\41.jpg;', '.\set001\42.jpg;', '.\set001\43.jpg;', '.\set001\44.jpg;', '.\set001\45.jpg;', ...
                 '.\set001\46.jpg;', '.\set001\47.jpg;', '.\set001\48.jpg;', '.\set001\49.jpg;', '.\set001\50.jpg;', ...
                 '.\set001\51.jpg;', '.\set001\52.jpg;', '.\set001\53.jpg;', '.\set001\54.jpg'};
    
    % Total number of different stimulus conditions.
    n_conditions = 4;
    
    % Time for sending header information and "trial end" markers, seconds.
    % During this time no stimuli are presented.
    transmission_time = 0.15; 
    
    % Stimulus conditions as they appear in the experiment.
    conditions = [];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Modify the following parameters only when needed. Act with caution!
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    IP_ADDRESS   = '169.254.209.8';
    CLIENT_PORT  = 9091;
    SERVER_PORT  = 9090;
    BUFFER_SIZE  = 1024;
    
    TIME_STEP    = 0.005; % sec
    WARMING_TIME = 1.0;   % sec
    
    CONNECTED    = 'connected';
    LOAD_STIMULI = 'load_stimuli';
    START_TEST   = 'start_test';
    STOP_TEST    = 'stop_test';
    EXIT_TEST    = 'exit_test';
    STOP_SERVER  = 'stop_server';  
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    global udp_object; 
    global curr_state;
    
    curr_state.all_states = {START_TEST, STOP_TEST, EXIT_TEST, STOP_SERVER};
    curr_state.pointer    = 2;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if establish_connection(IP_ADDRESS, CLIENT_PORT, SERVER_PORT, BUFFER_SIZE, EXIT_TEST)
        return;
    end
    
    % Set up an input/output object to send trial data to the Cheetah data
    % acquisition system.
    io_object = digitalio('mcc', 1);
    addline(io_object, 0:7, 'out'); 

    % Presentation order of different stimulus conditions.
    presentation_order.sequence = randperm(n_conditions);
    presentation_order.pointer  = 1;
    
    % Number of trials. 
    trial_no = 0; 
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
      
    fig_handle = show_controls;
    fprintf(udp_object, CONNECTED), pause(WARMING_TIME);
    fprintf(udp_object, LOAD_STIMULI);
    fprintf(udp_object, cell2mat(filenames));

    while ishandle(fig_handle)
        
        switch curr_state.pointer
            
            case 1 % START_TEST                
                [stim_condition, presentation_order] = next_condition(presentation_order);
                current_command = sprintf(command_template, stim_condition);
                trial_no = trial_no + 1;
                fprintf('Trial no. %03d: %s\n', trial_no, current_command);
                
                send_header_info(io_object, exp_id, stim_condition);
                conditions(end + 1) = stim_condition;
                pause(transmission_time);
                
                fprintf(udp_object, current_command);                
                pause(trial_duration);
                
                send_trial_end(io_object);
                pause(transmission_time);
                
            case 2 % STOP_TEST
                % Do nothing.
                
            case 3 % STOP_SERVER
                fprintf(udp_object, STOP_SERVER);
                break;
                
        end
        
        pause(TIME_STEP);
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    close_connection(EXIT_TEST);
    close(gcf);
    
    save(datestr(clock, 'yyyy-mm-dd HH-MM-SS'), 'command_template', 'trial_duration',  ...
         'exp_id', 'n_conditions', 'transmission_time', 'conditions', 'TIME_STEP');
    
end

function exit_code = establish_connection(ip_address, client_port, server_port, buffer_size, server_msg_on_error)

    global udp_object;

    % Denotes a successfully established connection. Otherwise, "1".
    exit_code = 0;
    
    try
        
        delete(instrfindall);
        udp_object = udp(ip_address, server_port, 'LocalPort', client_port);
        udp_object.OutputBufferSize = buffer_size;
        udp_object.OutputDatagramPacketSize = buffer_size;
        fopen(udp_object);
        fprintf('Successfully established a connection.\n');
        
    catch err

        exit_code = 1;
        close_connection(server_msg_on_error);
        fprintf('Failed to establish a connection.\n');
        
    end
    
end

function close_connection(msg)

    global udp_object;
    
    try
        
        fprintf(udp_object, msg);
        fclose(udp_object);
        delete(udp_object);
        fprintf('Successfully closed the connection.\n');
    
    catch err
        
        fprintf('Failed to close the connection.\n');
        
    end
        
end

function fig_handle = show_controls

    fig_handle = figure;
    uicontrol('Style', 'PushButton', 'Position', [ 10 10 75 25], 'String', 'Start test', 'Callback', {@button_push, 1});
    uicontrol('Style', 'PushButton', 'Position', [ 95 10 75 25], 'String', 'Stop test', 'Callback', {@button_push, 2});
    uicontrol('Style', 'PushButton', 'Position', [180 10 75 25], 'String', 'Stop server', 'Callback', {@button_push, 3});
    set(fig_handle, 'Position', [400, 500, 275, 45]);
    set(fig_handle, 'Name', 'Experiment controls', 'NumberTitle', 'off');
    
end

function button_push(varargin)

    global curr_state;
    curr_state.pointer = varargin{3};
    
end

function send_header_info(io_object, exp_id, stim_condition)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Header has a fixed (predetermined) structure. Modify only when needed.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Number of bits in binary format.
    % n_bits = 8;
    
    % Header start.
	% putvalue(io_object, fliplr(dec2bin(254, n_bits)) - '0');
	% putvalue(io_object, fliplr(dec2bin(0, n_bits)) - '0');
    putvalue(io_object, 254);
	putvalue(io_object, 0);
    
    % Experiment identifier.
    % putvalue(io_object, fliplr(dec2bin(exp_id, n_bits)) - '0');
	% putvalue(io_object, fliplr(dec2bin(0, n_bits)) - '0');
    putvalue(io_object, exp_id);
	putvalue(io_object, 0);
    
    % Condition label.
 	% putvalue(io_object, fliplr(dec2bin(stim_condition, n_bits)) - '0');
 	% putvalue(io_object, fliplr(dec2bin(0, n_bits)) - '0');
    putvalue(io_object, stim_condition);
    putvalue(io_object, 0);
    
    % Header end.
 	% putvalue(io_object, fliplr(dec2bin(253, n_bits)) - '0');   
	% putvalue(io_object, fliplr(dec2bin(0, n_bits)) - '0');
    putvalue(io_object, 253);
    putvalue(io_object, 0);
            
end

function send_trial_end(io_object)

    % Number of bits in binary format.
    % n_bits = 8;

    % Send the marker of trial end.
 	% putvalue(io_object, fliplr(dec2bin(252, n_bits)) - '0');   
	% putvalue(io_object, fliplr(dec2bin(0, n_bits)) - '0');
    putvalue(io_object, 252);   
	putvalue(io_object, 0);
    
end

function [stim_condition, presentation_order] = next_condition(presentation_order)

    stim_condition             = presentation_order.sequence(presentation_order.pointer);
    presentation_order.pointer = presentation_order.pointer + 1;

    full_sequence_length = length(presentation_order.sequence);
    if presentation_order.pointer > full_sequence_length
        presentation_order.sequence = randperm(full_sequence_length);
        presentation_order.pointer  = 1;
    end
    
end
