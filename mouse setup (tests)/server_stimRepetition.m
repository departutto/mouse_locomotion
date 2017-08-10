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
            first_presented  = stimuli{stim_a};
            second_presented = stimuli{stim_a};
        case 2
            first_presented  = stimuli{stim_a};
            second_presented = stimuli{stim_b};
        case 3
            first_presented  = stimuli{stim_b};
            second_presented = stimuli{stim_a};
        case 4
            first_presented  = stimuli{stim_b};
            second_presented = stimuli{stim_b};
        otherwise
            return;
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
