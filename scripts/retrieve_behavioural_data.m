function [trial_data, raw_data] = retrieve_behavioural_data
    
    % Select a file with behavioral information (*.nev).
    [filename, curr_dir] = uigetfile('*.nev', 'Select Events file (*.nev)');
    if ~curr_dir
        return;
    end
    fprintf('Events file: %s\n', [curr_dir filename]);
    
    % Extract raw behavioral data and convert them into a structured format:
    %  - row #N: timestamp, sec x port identifier x ttl.
    raw_data   = retrieve_raw_data([curr_dir filename]);
    
    % Split raw behavioral data per trial, wich each trial containing the
    % following information:
    %  - trial start and stop events, sec;
    %  - header start, sec;
    %  - experiment type and condition label;
    %  - photocell events, sec;
    %  - displacement of the running wheel, digital units.
    trial_data = split_raw_data_per_trial(raw_data);
    
end

function trial_data = split_raw_data_per_trial(raw_data)

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

function consolidated = retrieve_raw_data(filename)   

    % Retrieve all events along with their timestamps.
    [timestamps, ttls, event_strings] = Nlx2MatEV(filename, [1 0 1 0 1], 0, 1, 1);

    % Beginning of a recording session (in usec).
    time0 = timestamps(1);
    
    % Align all retrieved events with respect to the beginning of a
    % recording session and convert their timestamps in sec.
    timestamps = (timestamps - time0) / 10 ^ 6;
    
    % Retrieve port identifier for each retrieved event. 
    port_id = retrieve_port_identifier(event_strings);
    
    consolidated = [timestamps' port_id' ttls'];
    
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
