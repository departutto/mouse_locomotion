% Last modified on August 10, 2017 by Dima.

function server_stimRepetition(varargin)

    global stimuli;
    
    % Pointer to the screen for stimulus presentation.
    window_pointer = varargin{1};
    
    % Stimulus condition.
    stim_condition = varargin{2};    
    
    % Duration of stimulus presentation and inter-stimulus interval (in frames).
    stim_duration = varargin{3}; 
    isi_duration = varargin{4};
    
    % Color of the blank screen between the adapter and test stimuli (in frames).
    isi_color = varargin{5};
    
    % Coordinates of the uppermost left corner of the stimuli on the screen .
    x0 = varargin{6};
    y0 = varargin{7};
    
    % Stimulus identifiers.
    stim_a = varargin{8};
    stim_b = varargin{9};
    
    % Time between the test stimulus offset and the trial end (in frames).
    iti_duration = varargin{10};
    
    % Dimensions of the flashing square under the photocell.
    photocell_dimensions = [1820, 1100, 1920, 1200];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Presentation order of the stimuli.   
    switch stim_condition
        case 1
            first_presented  = stimuli{1};
            second_presented = stimuli{1};
        case 2
            first_presented  = stimuli{1};
            second_presented = stimuli{2};
        case 3
            first_presented  = stimuli{1};
            second_presented = stimuli{3};
        case 4
            first_presented  = stimuli{1};
            second_presented = stimuli{4};
        case 5
            first_presented  = stimuli{1};
            second_presented = stimuli{5};
        case 6
            first_presented  = stimuli{1};
            second_presented = stimuli{6};
        case 7
            first_presented  = stimuli{2};
            second_presented = stimuli{1};
        case 8
            first_presented  = stimuli{2};
            second_presented = stimuli{2};
        case 9
            first_presented  = stimuli{2};
            second_presented = stimuli{3};
        case 10
            first_presented  = stimuli{2};
            second_presented = stimuli{4};
        case 11
            first_presented  = stimuli{2};
            second_presented = stimuli{5};
        case 12
            first_presented  = stimuli{2};
            second_presented = stimuli{6};
        case 13
            first_presented  = stimuli{3};
            second_presented = stimuli{1};
        case 14
            first_presented  = stimuli{3};
            second_presented = stimuli{2};
        case 15
            first_presented  = stimuli{3};
            second_presented = stimuli{3};
        case 16
            first_presented  = stimuli{3};
            second_presented = stimuli{4};
        case 17
            first_presented  = stimuli{3};
            second_presented = stimuli{5};
        case 18
            first_presented  = stimuli{3};
            second_presented = stimuli{6};
        case 19
            first_presented  = stimuli{4};
            second_presented = stimuli{1};
        case 20
            first_presented  = stimuli{4};
            second_presented = stimuli{2};
        case 21
            first_presented  = stimuli{4};
            second_presented = stimuli{3};
        case 22
            first_presented  = stimuli{4};
            second_presented = stimuli{4};
        case 23
            first_presented  = stimuli{4};
            second_presented = stimuli{5};
        case 24
            first_presented  = stimuli{4};
            second_presented = stimuli{6};
        case 25
            first_presented  = stimuli{5};
            second_presented = stimuli{1};
        case 26
            first_presented  = stimuli{5};
            second_presented = stimuli{2};
        case 27
            first_presented  = stimuli{5};
            second_presented = stimuli{3};
        case 28
            first_presented  = stimuli{5};
            second_presented = stimuli{4};
        case 29
            first_presented  = stimuli{5};
            second_presented = stimuli{5};
        case 30
            first_presented  = stimuli{5};
            second_presented = stimuli{6};
        case 31
            first_presented  = stimuli{6};
            second_presented = stimuli{1};
        case 32
            first_presented  = stimuli{6};
            second_presented = stimuli{2};
        case 33
            first_presented  = stimuli{6};
            second_presented = stimuli{3};
        case 34
            first_presented  = stimuli{6};
            second_presented = stimuli{4};
        case 35
            first_presented  = stimuli{6};
            second_presented = stimuli{5};
        case 36
            first_presented  = stimuli{6};
            second_presented = stimuli{6};
    end
    
    % Width and height of the stimuli assuming that both are of the same size.
    stim_dimensions = Screen('Rect', first_presented);
    stim_width      = stim_dimensions(3);
    stim_height     = stim_dimensions(4);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Present the adapter stimulus.
    for counter = 1:stim_duration
        
        Screen('FillRect', window_pointer, isi_color);
        Screen('DrawTexture', window_pointer, first_presented, [], [x0 y0 x0 + stim_width - 1 y0 + stim_height - 1]);
        
        % Trigger photocell events on the first and last frames only.
        if counter == 1 || counter == stim_duration
            Screen('FillRect', window_pointer, 255, photocell_dimensions);
        else
            Screen('FillRect', window_pointer, 0, photocell_dimensions);
        end
        
        Screen('Flip', window_pointer);
        
    end
    
    % Present an inter-stimulus interval.
    for counter = 1:isi_duration
    
        Screen('FillRect', window_pointer, isi_color);
        Screen('FillRect', window_pointer, 0, photocell_dimensions);
        Screen('Flip', window_pointer);        
    
    end
    
    % Present the test stimulus.
    for counter = 1:stim_duration
        
        Screen('FillRect', window_pointer, isi_color);
        Screen('DrawTexture', window_pointer, second_presented, [], [x0 y0 x0 + stim_width - 1 y0 + stim_height - 1]);
        
        % Trigger photocell events on the first and last frames only.
        if counter == 1 || counter == stim_duration
            Screen('FillRect', window_pointer, 255, photocell_dimensions);
        else
            Screen('FillRect', window_pointer, 0, photocell_dimensions);
        end
        
        Screen('Flip', window_pointer);
        
    end
    
    % Wait before you end the trial.
    for counter = 1:iti_duration
    
        Screen('FillRect', window_pointer, isi_color);
        Screen('FillRect', window_pointer, 0, photocell_dimensions);
        Screen('Flip', window_pointer);        
    
    end
    
end
