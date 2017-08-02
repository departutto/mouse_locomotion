function plot_online_PSTHs
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Parameters to modify.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    
    % Channel of interest used for data sampling.
    acq_entity    = 'SE1';
    
    % PSTH parameters (milliseconds).
    bin_width     = 10;  
    baseline      = 300;
    stim_duration = 600; 
    
    % Number of rows and columns in the figure with PSTHs.
    n_rows        = 4;
    n_columns     = 6;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Complementary parameters. Modify only when neccessary.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    
    global psths;
    global n_trials;
       
    % Used to connect to the Cheetah data acquisition system.
    server_name   = 'localhost';
     
    % Time in-between the two consecutive readings from the Cheetah data 
    % acquisition system (seconds).
    sampling_time = 0.5; 
    
    % Number of stimulus conditions.
    n_conds       = n_rows * n_columns;
    
    % Time bins for online PSTHs.
    bins          = -baseline:bin_width:stim_duration;
    
    % Online PSTHs (spikes/sec).
    psths         = zeros(n_conds, length(bins));
    
    % Number of analyzed trials per stimulus condition.
    n_trials      = zeros(1, n_conds);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Establish a connection with the Cheetah data acquisition system.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    warning('off');
    exit_code = establish_connection(server_name, acq_entity);
    if exit_code
        return;
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Retrieve experimental data and plot online PSTHs.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    fig_with_psths = figure;
    uicontrol('Style', 'PushButton', 'String', 'Clear plots', 'Callback', 'clear_button', 'Position', [10 10 75 25]);
    uicontrol('Style', 'PushButton', 'String', 'Terminate', 'Callback', 'delete(gcbf)', 'Position', [95 10 75 25]);
    
    raw_data       = [];
    all_spikes     = [];
    
    while ishandle(fig_with_psths)
        
        [~, timestamps, ~, ttls, descriptors] = NlxGetNewEventData('Events');
        [~, ~, spike_train] = NlxGetNewSEData(acq_entity);      
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        [raw_data, all_spikes, trial_data] = process_data(raw_data, all_spikes, timestamps, ...
                                                          ttls, descriptors, spike_train,   ...
                                                          baseline, stim_duration);   
        [psths, n_trials] = update_PSTHs(psths, n_trials, bins, bin_width, trial_data);
        plot_PSTHs(psths, n_rows, n_columns, n_trials, bins);
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        pause(sampling_time);
        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Close all open channels and quit the script.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    close_connection(acq_entity);
    warning('on');
    
end

function clear_button
	
    global psths;
    global n_trials;
    
    psths    = zeros(size(psths));
    n_trials = zeros(size(n_trials));
    
    fprintf('Successfully cleared the current plots.\n');
    
end

function exit_code = establish_connection(server_name, acq_entity)    

    % Before all commands are executed, we assume a failure in the function.
    exit_code = 1;
    
    try 
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Connect to Cheetah.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        if ~NlxAreWeConnected()    
            succeeded = NlxConnectToServer(server_name);
            if succeeded ~= 1
                fprintf('Failed to connect to %s.\n', server_name);
                return;
            end
        end

        fprintf('Successfully connected to %s.\n', server_name);

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Check existence of the acquisition entity of interest.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        [~, cheetahObjects, ~] = NlxGetDASObjectsAndTypes();

        if any(strcmp(acq_entity, cheetahObjects))
            fprintf('Successfully detected data acquisition entity %s.\n', acq_entity);
        else
            fprintf('Failed to detect data acquisition entity %s.\n', acq_entity);
            NlxDisconnectFromServer();
            return;
        end

        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Open channels of interest and start streaming.
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

        NlxSetApplicationName('Online PSTHs in Matlab');

        if NlxOpenStream('Events') ~= 1 || NlxOpenStream(acq_entity) ~= 1   
            fprintf('Failed to access data acquisition entity %s.\n', acq_entity);
            NlxDisconnectFromServer();
            return;        
        end

        if NlxSendCommand('-StartAcquisition') == 1
            fprintf('Successfully initiated data acquisition from %s.\n', acq_entity);   
        else
            fprintf('Failed to initiate data acquisition from %s.\n', acq_entity);
            NlxCloseStream('Events');
            NlxCloseStream(acq_entity);
            NlxDisconnectFromServer();
            return;
        end
        
    catch err
        
        fprintf('Critical error: %s\n', err);
        return;
        
    end    
     
    % Function is successfully executed.
    exit_code = 0;
    
end

function close_connection(acq_entity)

    try
        
        NlxSendCommand('-StopAcquisition');
        NlxCloseStream('Events');
        NlxCloseStream(acq_entity);
        NlxDisconnectFromServer();    
        fprintf('Quitted the script!\n');
        
    catch err
        
        fprintf('Critical error: %s\n', err);
        
    end
    
end

function [raw_data, all_spikes, trial_data] = process_data(raw_data, all_spikes, timestamps, ...
                                                           ttls, descriptors, spike_train,   ...
                                                           baseline, stim_duration)
    
    trial_data    = struct([]);
    
    % Convert in microseconds.
    baseline      = baseline * 10 ^ 3;
    stim_duration = stim_duration * 10 ^ 3;
    
    % Add new spikes.
    all_spikes = [all_spikes spike_train];
    
    % Number of data points.
    n_points = size(timestamps, 1);
    if ~n_points 
        return;
    end
    
    % Analyze only data from the experiment and discard the Cheetah service tags.  
    search_word = 'TTL Input';
    to_include  = true(n_points, 1) & strncmp(descriptors, search_word, length(search_word));   
    timestamps  = timestamps(to_include);
    ttls        = ttls(to_include);
    descriptors = cell2mat(descriptors(to_include)); 
    
    % Only service tags were detected.
    if ~size(descriptors, 1)
        return;
    end

    % Retrieve port identifier.    
    port_id = descriptors(:, 40) - '0';
    
    % Update raw data structure.
    raw_data = [raw_data; timestamps' ttls' port_id];
    
    % Trial start marker x Port identifier.
    trial_start = find(raw_data(:, 2) == 254 & raw_data(:, 3) == 1); 
    if isempty(trial_start)
        return;
    end
    
    % Trial stop marker x Port identifier.
    index0     = trial_start(1);
    trial_stop = find(raw_data(index0:end, 2) == 252 & raw_data(index0:end, 3) == 1);
    trial_stop = trial_stop + index0 - 1;
    
    % Number of trials.
    n_trials = min([length(trial_start) length(trial_stop)]);
    if ~n_trials
        return;
    end
    
    for counter = 1:n_trials
        
        selection  = trial_start(counter):trial_stop(counter);
        curr_trial = raw_data(selection, :);      

        % Detect photocell events in a trial.
        selection  = curr_trial(:, 2) == 2 & curr_trial(:, 3) == 0;
        photocells = curr_trial(selection, 1);
        
        selection  = curr_trial(:, 3) == 1;
        curr_trial = curr_trial(selection, :);
        
        % Validate header structure. 
        if curr_trial(1, 2) ~= 254 || curr_trial(2, 2) ~= 0 || ...
           curr_trial(3, 2) < 1    || curr_trial(4, 2) ~= 0 || ...
           curr_trial(5, 2) < 1    || curr_trial(6, 2) ~= 0 || ...
           curr_trial(7, 2) ~= 253 || curr_trial(8, 2) ~= 0 || ...
           curr_trial(9, 2) ~= 252 || isempty(photocells)
            fprintf('Skipping one trial with corrupted header information.\n');
        else
            % Extract trial information from the header.
            trial_data(end + 1).header_start = curr_trial(1, 1);
            trial_data(end).header_stop      = curr_trial(7, 1);
            trial_data(end).trial_stop       = curr_trial(9, 1);
            trial_data(end).experiment_type  = curr_trial(3, 2);
            trial_data(end).condition        = curr_trial(5, 2);
            trial_data(end).stimulus_onset   = photocells(1);
            
            % Select all spikes within a trial.
            analysis_window_start            = trial_data(end).stimulus_onset - baseline;
            analysis_window_end              = trial_data(end).stimulus_onset + stim_duration;
            selection                        = all_spikes >= analysis_window_start & all_spikes <= analysis_window_end;
            trial_data(end).spikes           = all_spikes(selection);
            
            fprintf('Experiment type x Condition label x N(photocell events) x N(spikes): %02d x %02d x %02d x %d\n', ...
                    trial_data(end).experiment_type, trial_data(end).condition, length(photocells), length(trial_data(end).spikes)); 
        end

    end
    
    % Remove analyzed spikes. 
    last_trial = trial_stop(n_trials);
    selection  = all_spikes >= raw_data(last_trial, 1) - baseline;
    all_spikes = all_spikes(selection);
    
    % Remove analyzed trials.
    raw_data   = raw_data(last_trial:end, :);
    
end

function [psths, n_trials] = update_PSTHs(psths, n_trials, bins, bin_width, trial_data)

    if isempty(trial_data)
        return;
    end
    
    for counter = 1:length(trial_data)
        
        condition = trial_data(counter).condition;
        spikes    = (trial_data(counter).spikes - trial_data(counter).stimulus_onset) / 10.0 ^ 3; % milliseconds.
        coeff     = 1000.0 / bin_width;
        response  = coeff * histc(double(spikes), bins); % spikes/second.
        
        if isempty(response)
            response = zeros(1, length(bins));
        end
        
        if n_trials(condition)
            psths(condition, :) = (psths(condition, :) * n_trials(condition) + response) / (n_trials(condition) + 1);
        else
            psths(condition, :) = response;
        end
        
        n_trials(condition) = n_trials(condition) + 1;

    end
    
end

function plot_PSTHs(psths, n_rows, n_columns, n_trials, bins)

    y_step         = 10;
    
    min_response   = 0; 
    max_response   = max(max(psths));    
    max_response   = max_response + y_step - mod(max_response, y_step);
    
    xrange         = [1 size(psths, 2) - 1];
    yrange         = [min_response max_response];
    yticks         = [min_response max_response];
    
    stimulus_onset = 1 + abs(bins(1)) / (bins(end) - bins(1)) * (length(bins) - 1);
    
    for row = 1:n_rows
        for col = 1:n_columns
            
            index = n_columns * (row - 1) + col;
            subplot(n_rows, n_columns, index), plot(psths(index, :), '-b'), hold on;
            plot([stimulus_onset stimulus_onset], yrange, '-r'), hold off;
            
            set(gca, 'XLim', xrange);
            set(gca, 'YLim', yrange);
            
            set(gca, 'XTick', [xrange(1) stimulus_onset xrange(end)]);
            set(gca, 'XTickLabel', [bins(1), 0, bins(end)]);
            set(gca, 'YTick', yticks);
            set(gca, 'YTickLabel', yticks);
            
            if row == n_rows
                xlabel('time, msec');
            end
            if col == 1
                ylabel('response, spikes/sec');
            end
            
            title(['Cond #' num2str(index) ': N = ' num2str(n_trials(index))]);
            
        end
    end
    
end
