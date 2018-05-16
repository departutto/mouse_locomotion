function incorporate_spikes(varargin)

    % Time interval before and after each photocell event used to analyze
    % spiking activity. Both values must be positive.
    BEFORE = 0.3; % seconds
    AFTER = 0.6;  % seconds
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    % If no KWIK file is provided in the input or the specified file does
    % not exist, show a file selection dialog.
    if isempty(varargin) || ~exist(varargin{1}, 'file')

        [kwik_filename, kwik_pathname] = uigetfile('*.kwik', 'File with sorted spikes (*.kwik)', cd, 'MultiSelect', 'off');

        % Quit if no file is selected in the dialog.
        if ~kwik_filename 
            fprintf('Exit code #1.\n');
            return;       
        end
        
        % Build a full filename of the selected KWIK file.
        kwik_fullname = fullfile(kwik_pathname, kwik_filename); 
        
    else
        
        kwik_fullname = varargin{1};
        
    end
    
    % Upload timestamp indices of the detected spikes along with their 
    % cluster allocation information into the Matlab workspace.
    try        
        spike_indices = hdf5read(kwik_fullname, '/channel_groups/0/spikes/time_samples');
        cluster_ids = hdf5read(kwik_fullname, '/channel_groups/0/spikes/clusters/main');
    catch err
        fprintf('Exit code #2.\n');
        return;
    end
    
    disp(kwik_fullname);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % If the second optional argument is provided, use that argument to 
    % define the list of analyzed clusters.
    if length(varargin) > 1 
        
        if isnumeric(varargin{2})
            
            % List of the cluster identifiers as specified by user.
            selection = varargin{2};

        elseif isequal(varargin{2}, 'all')
            
            % List of all cluster identifiers retrieved from the KWIK file.
            selection = unique(cluster_ids); 
            
        end
        
    end
    
    % If no cluster identifier is specified by user or the selection turns 
    % out to be empty, select manually clusters to analyze.
    if ~exist('selection', 'var') || isempty(selection)

        selection = select_clusters(cluster_ids);

        % Quit if no cluster is selected.
        if isempty(selection)
            fprintf('Exit code #3.\n');
            return;
        end
    
    end
    
    disp(selection);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % If the third optional argument is provided, use that argument as a full
    % path to the file with timestamps at which the spiking signal was sampled.
    % The specified file must contain variable 'timestamps'.
    if length(varargin) > 2 && exist(varargin{3}, 'file') && ~isempty(who('-file', varargin{3}, 'timestamps'))
        
        time_fullname = varargin{3};
        
    else
        
        % If no filename is specified, try to locate the file with
        % timestamps in the same directory as the KWIK file. The sought
        % file is assumed to have the .mat extension. 
        [dst, filename, ext] = fileparts(kwik_fullname);
        time_fullname = fullfile(dst, [filename '.mat']);    
        
        % If failed, the user is offered to select the MAT file manually.
        if ~exist(time_fullname, 'file') || isempty(who('-file', time_fullname, 'timestamps'))
            
            [time_filename, time_pathname] = uigetfile('*.mat', 'File with timestamps (*.mat)', fileparts(kwik_fullname), 'MultiSelect', 'off');
            
            % Quit if no file is selected in the dialog.
            if ~time_filename 
                fprintf('Exit code #4.\n');
                return;       
            end
            
            % Build a full filename of the selected MAT file.
            time_fullname = fullfile(time_pathname, time_filename);
            
            % Quit if the selected MAT file does not contain variable 'timestamps'.
            if isempty(who('-file', time_fullname, 'timestamps'))
                fprintf('Exit code #5.\n');
                return; 
            end
            
        end
        
    end
    
    load(time_fullname, 'timestamps');
    disp(time_fullname);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    
    % If the fourth optional argument is provided, use that argument as a full
    % path to the file with trial information. The specified file must
    % contain variables 'trials' and 'time0'.
    if length(varargin) > 3 && exist(varargin{4}, 'file') && ...
       ~isempty(who('-file', varargin{4}, 'trials'))      && ...
       ~isempty(who('-file', varargin{4}, 'time0'))
   
        trials_fullname = varargin{4};
        
    else
        
        [trials_filename, trials_pathname] = uigetfile('*.mat', 'File with trial information (*.mat)', fileparts(kwik_fullname), 'MultiSelect', 'off');
        
        % Quit if no file is selected in the dialog.
        if ~trials_filename 
            fprintf('Exit code #6.\n');
            return;       
        end
        
        % Build a full filename of the selected MAT file.
        trials_fullname = fullfile(trials_pathname, trials_filename);
        
        % Quit if the selected MAT file does not contain variable 'trials'
        % or 'time0'.
        if isempty(who('-file', trials_fullname, 'trials')) || ...
           isempty(who('-file', trials_fullname, 'time0'))     
            fprintf('Exit code #7.\n');
            return; 
        end
   
    end
    
    load(trials_fullname);
    disp(trials_fullname);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Retrieve spike timestamps and convert them into seconds.
    spike_timestamps = (timestamps(spike_indices) - time0) / 10.0 ^ 6;
    
    % Copy of the original variable 'trials'.
    orig_trials = trials;
    
    
    [~, kwik_filename] = fileparts(kwik_fullname);
    [dst, trials_filename] = fileparts(trials_fullname);
    
    for counter = 1:length(selection)
        
        current_cluster = selection(counter);
        selected_spikes = cluster_ids == current_cluster;
        selected_spikes = spike_timestamps(selected_spikes);
        fprintf('Cluster #%02d: N(spikes) = %d\n', current_cluster, length(selected_spikes));
        
        trials = process_one_cluster(orig_trials, selected_spikes, BEFORE, AFTER);
        target_file = fullfile(dst, [kwik_filename '-' trials_filename '-cluster-' num2str(current_cluster) '.mat']);
        save(target_file, 'trials');
        
    end    
    
end

function selection = select_clusters(cluster_ids)

    % Unique cluster identifiers.
    unique_ids = unique(cluster_ids);

    % Number of different clusters. 
    n_clusters = length(unique_ids);

    % Number of spikes in each cluster.
    n_spikes = [];

    % String description of all the retrieved clusters in a form "Cluster # (Number of spikes)".
    descriptors = {};

    for counter = 1:n_clusters
        curr_cluster = unique_ids(counter);
        n_spikes(end + 1) = sum(cluster_ids == curr_cluster);
        descriptors{end + 1} = [num2str(curr_cluster) ' (' num2str(n_spikes(counter)) ')'];
    end

    % Display a list selection dialog with all the retrieved clusters.
    selection = listdlg('PromptString', 'Select a cluster (or clusters)', ...
                        'SelectionMode', 'multiple', ...
                        'ListString', descriptors); 

    % List of the cluster identifiers selected by user.
    selection = unique_ids(selection);

end

function trials = process_one_cluster(trials, spikes, before, after)

    for counter = 1:length(trials)

        trials(counter).spikes = {};
        
        for photoevent_no = 1:length(trials(counter).photoevents)
            
            earliest = trials(counter).photoevents(photoevent_no) - before; % sec.
            latest = trials(counter).photoevents(photoevent_no) + after;    % sec.
            indices = earliest <= spikes & spikes <= latest;
            trials(counter).spikes{end + 1} = spikes(indices);
            
        end

    end
    
end
