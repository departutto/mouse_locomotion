 % Last modified on September 7, 2017 by Dima.

function client_discrimination
    
    % Command string per trial executed on the server side:
    %   param #1 - pointer to the screen for stimulus presentation;
    %   param #2 - stimulus condition;
    %   param #3 - duration of stimulus presentation, frames; (60frames=1s)
    %   param #4 - duration of inter-stimulus interval (ISI), frames;
    %   param #5 - color of the blank screen during ISI, unsigned byte;
    %   params #6 and 7 - coordinates of the uppermost left corner of the
    %                     stimuli on the screen, unsigned bytes.
    command_template = 'server_discrimination(window_pointer, %02d, 150, 240, 128, 361, 1)';
    
    % Duration of the following phases in a trial relative to stimulus onset:
    % - punishment at the beginning of stimulus presentation if animal licks;
    % - reward delivery if animal makes a correct choice;
    % - punishment after (or even during) stimulus presentation if animal licks.
    % IMPORTANT! When being summed up, the total duration of all phases should be 
    % sufficient to accomodate stimulus presentation and inter-stimulus interval,
    % as specified above.
    phases = [0.0 2.5 4.0]; % in seconds.   
    
    % Stimuli.
    filenames = {'.\set001\01.tif;', '.\set001\02.tif'};
    
    % For each stimulus in variable 'filenames' specify licking of which spout
    % is rewarded during presentation of that stimulus. The values of true 
    % and false correspond to the left and right spouts, respectively.
    % IMPORTANT! The number of elements in both 'filenames' and
    % 'corr_choice' must be matched! 
    corr_choice = [true false];
    % To reverse the spout x stimulu mapping, uncomment the following line.
    % corr_choice = ~corr_choice;
   
    % Period during which the pumps are open, in seconds.
    reward_duration = 0.04;
    
    % Frequency and duration of the tone for punishing an animal, in Hz and seconds.
    tone_fs  = 5000; 
    tone_dur = 2.0;
    
    % Frequency at which the tone is played by the audio system, in Hz.
    audio_fs = 8192;   

    % Experiment identifier.
    exp_id = 66;
    
    % Total number of different stimulus conditions.
    n_conditions = length(filenames);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Modify the following parameters only when needed. Act with caution!
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    IP_ADDRESS   = '169.254.209.8';
    CLIENT_PORT  = 9091;
    SERVER_PORT  = 9090;
    BUFFER_SIZE  = 1024;
    
    TIME_STEP    = 0.001; % sec
    WARMING_TIME = 1.0;   % sec
    
    CONNECTED    = 'connected';
    LOAD_STIMULI = 'load_stimuli';
    START_TEST   = 'start_test';
    STOP_TEST    = 'stop_test';
    EXIT_TEST    = 'exit_test';
    STOP_SERVER  = 'stop_server';  
    
    % Identifiers of the left and right spouts:
    % - row #1 - to detect licks;
    % - row #2 - to deliver water reward.
    SPOUT_IDS    = [2 3; 1 5];
    
    % Threshold to detect licking.
    LICK_THR     = 20;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    global udp_object; 
    global curr_state;
    
    curr_state.all_states = {START_TEST, STOP_TEST, EXIT_TEST, STOP_SERVER};
    curr_state.pointer    = 2;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if establish_connection(IP_ADDRESS, CLIENT_PORT, SERVER_PORT, BUFFER_SIZE, EXIT_TEST)
        return;
    end
    
    licking_ports = connect_to_licking_ports;
    if isempty(licking_ports)
        return;
    end
    
    % Set up an input/output object to deliver water reward to the animals.
    reward_io = digitalio('mcc', 0);
    addline(reward_io, 0:7, 'out');
    
    % Set up an input/output object to send trial data to the Cheetah data
    % acquisition system.
    cheetah_io = digitalio('mcc', 1);
    addline(cheetah_io, 0:7, 'out'); 

    % Presentation order of different stimulus conditions.
    presentation_order.sequence = randperm(n_conditions);
    presentation_order.pointer  = 1;
    
    % Number of trials. 
    trial_no = 0; 
    
    % Tone played to punish an animal.
    timings = 0:(1.0 / audio_fs):tone_dur;
    tone    = sin(2 * pi * tone_fs * timings);    
    
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
                
                send_header_info(cheetah_io, exp_id, stim_condition);
                fprintf(udp_object, current_command);                 
                process_licking_events(licking_ports, SPOUT_IDS, LICK_THR, TIME_STEP, ...
                                       phases, corr_choice(stim_condition), reward_io, reward_duration, tone, audio_fs);
                send_trial_end(cheetah_io);
                
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
    release_phidgets(licking_ports);
        
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

function release_phidgets(licking_ports)

    calllib('phidget21', 'CPhidget_close', licking_ports);
	calllib('phidget21', 'CPhidget_delete', licking_ports);
    unloadlibrary('phidget21');
    
end

function licking_ports = connect_to_licking_ports
    
    try
        
        loadphidget21;
        licking_ports = libpointer('int32Ptr');
        calllib('phidget21', 'CPhidgetInterfaceKit_create', licking_ports);
        calllib('phidget21', 'CPhidget_open', licking_ports, -1);
        
    catch err
        
        licking_ports = [];
        fprintf('Failed to connect to the licking ports.\n');
        
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

function send_header_info(cheetah_io, exp_id, stim_condition)

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Header has a fixed (predetermined) structure. Modify only when needed.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Number of bits in binary format.
    n_bits = 8;
    
    % Header start.
	putvalue(cheetah_io, fliplr(dec2bin(254, n_bits)) - '0');
	putvalue(cheetah_io, fliplr(dec2bin(0, n_bits)) - '0');
    
    % Experiment identifier.
    putvalue(cheetah_io, fliplr(dec2bin(exp_id, n_bits)) - '0');
	putvalue(cheetah_io, fliplr(dec2bin(0, n_bits)) - '0');
    
    % Condition label.
 	putvalue(cheetah_io, fliplr(dec2bin(stim_condition, n_bits)) - '0');
 	putvalue(cheetah_io, fliplr(dec2bin(0, n_bits)) - '0');
    
    % Header end.
 	putvalue(cheetah_io, fliplr(dec2bin(253, n_bits)) - '0');   
	putvalue(cheetah_io, fliplr(dec2bin(0, n_bits)) - '0');
            
end

function send_trial_end(cheetah_io)

    % Number of bits in binary format.
    n_bits = 8;

    % Send the marker of trial end.
 	putvalue(cheetah_io, fliplr(dec2bin(252, n_bits)) - '0');   
	putvalue(cheetah_io, fliplr(dec2bin(0, n_bits)) - '0');

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

function process_licking_events(licking_ports, spout_ids, lick_thr, time_step, phases, corr_choice, reward_io, reward_duration, tone, audio_fs)   
    
    % Animal licks a spout at the beginning of stimulus presentation.
    % Animal should be punished in this case.
    timer1 = timer('TimerFcn', 'disp('''')', 'StartDelay', phases(1)); % sec
    
    % Animal licks a spout during stimulus presentation. Depending on which
    % spout is being licked, animal can be rewarded.
    timer2 = timer('TimerFcn', 'disp('''')', 'StartDelay', phases(2)); % sec
    
    % Animal licks a spout after stimulus presentation. Animal should be
    % punished.
    timer3 = timer('TimerFcn', 'disp('''')', 'StartDelay', phases(3)); % sec
    
    % Animal can be rewarded or punished only once during a trial.
    rewarded = false;
    punished = false;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    start(timer1);
    while strcmp('on', get(timer1, 'Running'))
        [left_lick, right_lick] = detect_licks(licking_ports, spout_ids, lick_thr); 
        % Animal touched a licking port (or both of them at the same time)
        % and now must be punished.
        if any([left_lick, right_lick]) && ~punished
            punish_animal(tone, audio_fs, 'Phase #1: Animal is punished.'); 
            punished = true;
        end
        pause(time_step);        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    start(timer2);
    while strcmp('on', get(timer2, 'Running'))
        [left_lick, right_lick] = detect_licks(licking_ports, spout_ids, lick_thr);
        
        % Both spouts were licked at the same time. Animal must be punished.
        if right_lick && left_lick && ~punished && ~rewarded
            punish_animal(tone, audio_fs, 'Phase #2: Animal is punished.'); 
            punished = true;
        end
        
        % Animal licked a wrong spout and, therefore, must be punished.
        if ((right_lick && ~left_lick && corr_choice) || (~right_lick && left_lick && ~corr_choice)) && ~punished && ~rewarded
            punish_animal(tone, audio_fs, 'Phase #2: Animal is punished.'); 
            punished = true;
        end
        
        % Left spout was licked correctly.
        if ~right_lick && left_lick && corr_choice && ~punished && ~rewarded
            reward_animal('left', spout_ids, reward_io, reward_duration, 'Phase 3 (LEFT): Animal is rewarded.');
            rewarded = true;
        end
        
        % Right spout was licked correctly.
        if right_lick && ~left_lick && ~corr_choice && ~punished && ~rewarded
            reward_animal('right', spout_ids, reward_io, reward_duration, 'Phase 3 (RIGHT): Animal is rewarded.');
            rewarded = true;
        end
        
        pause(time_step);
    end
        
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    start(timer3);
    while strcmp('on', get(timer3, 'Running'))
        [left_lick, right_lick] = detect_licks(licking_ports, spout_ids, lick_thr);
        % Animal touched a licking port (or both of them at the same time)
        % and now must be punished.
        if any([left_lick, right_lick])
            punish_animal(tone, audio_fs, 'Phase #3: Animal is punished.');       
            punished = true;
        end
        pause(time_step);
    end
    
end

function [left_lick, right_lick] = detect_licks(licking_ports, spout_ids, lick_threshold)

    left_spout  = spout_ids(1, 1);
    right_spout = spout_ids(1, 2); 
    
    left_lick   = analogin(left_spout, licking_ports) > lick_threshold;
	right_lick  = analogin(right_spout, licking_ports) > lick_threshold;

end

function reward_animal(spout_side, spout_ids, reward_io, reward_duration, msg)

    left_spout  = spout_ids(2, 1);
    right_spout = spout_ids(2, 2);
    
    switch spout_side
        case 'left'
            % Open valve.
            putvalue(reward_io.line(left_spout), 1);
            pause(reward_duration);
            % Close valve.
            putvalue(reward_io.line(left_spout), 0);
        case 'right'
            putvalue(reward_io.line(right_spout), 1);
            pause(reward_duration);
            putvalue(reward_io.line(right_spout), 0);            
    end
    
    fprintf('%s\n', msg);
    
end

function punish_animal(tone, audio_fs, msg)

    fprintf('%s\n', msg);
    
    % Comment the following line if tone delivery must be eliminated.
    sound(tone, audio_fs);

end
