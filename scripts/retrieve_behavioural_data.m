function [trial_data, raw_data] = retrieve_behavioural_data
    
    [file_name, path_name] = uigetfile('*.nev', 'Select Events file (*.nev)');
    if ~file_name
        clear file_name path_name;
        return;
    else
        full_name = [path_name file_name];
        fprintf('Events file: %s\n', full_name);
    end
    
    raw_data   = retrieve_raw_data(full_name);
    trial_data = split_per_trial(raw_data);
    trial_data = compute_velocity(trial_data);
    
end

function trial_data = compute_velocity(trial_data)
    
    for trial_no = 1:length(trial_data)
        
        displacement = trial_data(trial_no).displacement;
        
        % Remove zeros between the displacement values.
        indices1 = 1:2:length(displacement);
        indices2 = 2:2:length(displacement);
        if all(displacement(indices1, 2))
            displacement = displacement(indices1, :);
        elseif all(displacement(indices2, 2))
            displacement = displacement(indices2, :);
        else
            error('Failed to convert displacement data!');
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Bits 7 x 6 x 5 x 4 x 3 x 2 x 1 x 0:
        %      - x V x V x V x V x V x V x S,
        % where V could be 0 or 1 and code displacement w.r.t. the previous
        % timestamp, and S codes the direction of displacement (clockwise
        % or counter-clockwise).
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        % Direction of motion (possible values: -1 and +1).
        direction = 2 * bitand(displacement(:, 2), 1) - 1;
        
        % Shift to the right by 1 bit to remove direction information. 
        displacement(:, 2) = direction .* bitshift(displacement(:, 2), -1);
        
        % Convert displacement from internal ticks to cm:
        % - 1 tick = 1 / 200 inch;
        % - 1 inch = 2.54 cm.
        displacement(:, 2) = 2.54 / 200 * displacement(:, 2);              % Numeric parameters to modify!             
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Filling in gaps in time with the "null" speed.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%              
        time_step        = 0.003;  % sec.                                  % Numeric parameter to modify!
        time_error       = 0.0001; % sec                                   % Numeric parameter to modify!
        margin           = time_step + time_error;
        
        if isempty(displacement) || displacement(1, 1) - trial_data(trial_no).start > margin
            displacement = [trial_data(trial_no).start 0; displacement];
        end
        
        if isempty(displacement) || trial_data(trial_no).stop - displacement(end, 1) > margin
            displacement = [displacement; trial_data(trial_no).stop 0];
        end
        
        adj_displacement = displacement(1, :); 
        for counter = 2:size(displacement, 1)            
            while displacement(counter, 1) - adj_displacement(end, 1) > margin
                adj_displacement(end + 1, :) = [adj_displacement(end, 1) + time_step 0];
            end                
            adj_displacement(end + 1, :) = displacement(counter, :);
        end
                    
        trial_data(trial_no).velocity = [adj_displacement(:, 1) adj_displacement(:, 2) / time_step];
        
        % For debugging purposes only. Comment when no needed.
        % dt = trial_data(trial_no).velocity(2:end, 1) - trial_data(trial_no).velocity(1:end - 1, 1);
        % fprintf('Trial #%d: min x mean x median x max = %.6f x %.6f x %.6f x %.6f\n', trial_no, min(dt), mean(dt), median(dt), max(dt));
        
    end
    
end

function trial_data = split_per_trial(raw_data)

    % All data are stored per trial.
    trial_data = struct([]);

    % Beginning of a trial (port identifier = 1 x proper label).
    header_start = find(raw_data(:, 2) == 1 & raw_data(:, 3) == 254);    
    
    for counter = 1:length(header_start)

        curr_index = header_start(counter);
        
        % End of a header (port identifier = 1 x proper label).
        header_stop = find(raw_data(curr_index:end, 2) == 1 & raw_data(curr_index:end, 3) == 253, 1) + curr_index - 1; 
        
        % End of a trial (port identifier = 1 x proper label).
        trial_stop = find(raw_data(curr_index:end, 2) == 1 & raw_data(curr_index:end, 3) == 252, 1) + curr_index - 1; 
        
        % If trial is incomplete, leave the loop.
        if isempty(header_stop) || isempty(trial_stop)
            break;
        end
        
        % Retrieve experiment type and condition number.
        indices = find(raw_data(curr_index + 1:header_stop - 1, 2) == 1 & raw_data(curr_index + 1:header_stop - 1, 3)) + curr_index;
        values = raw_data(indices, 3);
        if length(values) ~= 2
            fprintf('Skipping a trial with corrupted header!\n');
            disp(raw_data(indices, :));
            continue;
        end
        
        % Retrieve photocell events.
        indices = find(raw_data(header_stop + 1:trial_stop - 1, 2) == 0 & raw_data(header_stop + 1:trial_stop - 1, 3) == 2) + header_stop;
        photocell = raw_data(indices, 1);
        
        % Retrieve displacement of the running wheel as detected by a laser motion sensor.
        indices = find(raw_data(curr_index:trial_stop, 2) == 2) + curr_index - 1;
        displacement = raw_data(indices, [1, 3]);
        
        % Adding a new trial.
        trial_data(end + 1).start    = raw_data(curr_index, 1);
        trial_data(end).header_stop  = raw_data(header_stop, 1);
        trial_data(end).stop         = raw_data(trial_stop, 1); 
        trial_data(end).exp_type     = values(1);
        trial_data(end).condition    = values(2);
        trial_data(end).photocell    = photocell;
        trial_data(end).displacement = displacement;
        
    end
    
end

function consolidated = retrieve_raw_data(file_name)   

    % Retrieve all events along with their timestamps.
    [time_stamps, ttls, event_strings] = Nlx2MatEV(file_name, [1 0 1 0 1], 0, 1, 1);

    % Beginning of a recording session (in usec).
    time0 = time_stamps(1);
    
    % Align all retrieved events with respect to the beginning of a
    % recording session and convert their timestamps in sec.
    time_stamps = (time_stamps - time0) / 10 ^ 6;
    
    % Retrieve port identifier for each retrieved event. 
    port_id = retrieve_port_identifier(event_strings);
    
    consolidated = [time_stamps' port_id' ttls'];
    
end

function port_id = retrieve_port_identifier(event_strings)

    n_records = size(event_strings, 1);
    port_id   = -ones(1, n_records);
    
    for counter = 1:n_records
        curr_string = event_strings{counter};
        if strfind(curr_string, 'port')               % avoids user's comments.
            port_id(counter) = curr_string(40) - '0'; % matches port identifier.
        end
    end
    
end
