% Last modified on August 22, 2017 by Dima.

function server_discrimination(varargin)

    global stimuli;
    
    % Pointer to the screen for stimulus presentation.
    window_pointer = varargin{1};
    
    % Stimulus condition.
    stim_condition = varargin{2};    
    
    % Duration of stimulus presentation and inter-stimulus interval (in frames).
    stim_duration = varargin{3}; 
    isi_duration = varargin{4};
    
    % Color of the blank screen between the two consecutive stimuli.
    isi_color = varargin{5};
    
    % Coordinates of the uppermost left corner of the stimuli on the screen .
    x0 = varargin{6};
    y0 = varargin{7};
    
    % Dimensions of the flashing square under the photocell.
    photocell_dimensions = [1820, 1100, 1920, 1200];
    
    % Width and height of the stimuli assuming that they are all of the same size.
    curr_stim       = stimuli{stim_condition};    
    stim_dimensions = Screen('Rect', curr_stim);
    stim_width      = stim_dimensions(3);
    stim_height     = stim_dimensions(4);
    
    % Present a stimulus.
    for counter = 1:stim_duration
        
        Screen('FillRect', window_pointer, isi_color);
        Screen('DrawTexture', window_pointer, curr_stim, [], [x0 y0 x0 + stim_width - 1 y0 + stim_height - 1]);
        
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
    
end
