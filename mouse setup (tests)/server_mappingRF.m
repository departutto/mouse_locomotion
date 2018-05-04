% Last modified on August 10, 2017 by Dima.

function server_mappingRF(varargin)

    % Pointer to the screen for stimulus presentation.
    window_pointer = varargin{1};
    
    % Stimulus condition.
    stim_condition = varargin{2};    
    
    % Duration of one flashing square and the following blank screen (in frames).
    stim_duration = varargin{3}; 
    isi_duration = varargin{4};
    
    % Color of the flashing squares.
    stim_color = varargin{5};
    
    % Color of the blank screen in-between the flashing squares.
    isi_color = varargin{6};
    
    % Dimensions of the square under the photocell.
    photocell_dimensions = [1820, 1100, 1920, 1200];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    % Tailored to the mouse setup with the monitor resolution of 1920 x 1200 
    % pixels. The default outline is 4 rows x 6 columns.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Checker width and height (in pixels).
    checker_width  = 320;
    checker_height = 300;
    
    % Coordinates of the uppermost left corner of all checkers on the screen.
    xcoor = 1:checker_width:1920; 
	ycoor = 1:checker_height:1200;

	coors = [];
    for row = 1:length(ycoor)
        for column = 1:length(xcoor)
            coors(end + 1, :) = [xcoor(column) ycoor(row)];
        end
    end  
    
    % Currently flashed checker.
    x0 = coors(stim_condition, 1);
    y0 = coors(stim_condition, 2);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Flash a checker.
    for counter = 1:stim_duration
        
        Screen('FillRect', window_pointer, isi_color);        
        Screen('FillRect', window_pointer, stim_color, [x0 y0 x0 + checker_width - 1 y0 + checker_height - 1]);
        
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
