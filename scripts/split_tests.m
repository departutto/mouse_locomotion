% Last modified on August 16, 2017 by Dima.

function split_tests

    % Select files to analyze.
    [files, curr_dir] = uigetfile('*.nev; *.ncs', 'Select file(s)', 'MultiSelect', 'on');
    if ~curr_dir
        return;
    end
    
    % Only one file is selected.
    if ~iscell(files)
        files = {files};
    end
        
    % Identify files with behavioral information (*.nev) and continuous signal (*.ncs).
    file_extensions = cellfun(@(x) x(end-2:end), files, 'UniformOutput', false);
    events_file     = cellfun(@(x) strcmp(x, 'nev'), file_extensions);
    ncs_files       = cellfun(@(x) strcmp(x, 'ncs'), file_extensions);
    
    if sum(events_file) ~= 1
        disp('No or more than one events file was detected!');
        return;
    else   
        events_file = files{events_file};
        ncs_files   = files(ncs_files);
        n_files     = length(ncs_files);
    end
    
    % Extract behavioral information from an events file (*.nev).
    [nev_timestamps, nev_eventids, nev_ttls, nev_extras, nev_eventstrings, nev_header] = Nlx2MatEV([curr_dir events_file], [1 1 1 1 1], 1, 1);
    
    % Identify the first record of each experimental test.
    indices = find(strcmp(nev_eventstrings, 'Starting Recording'));
    n_tests = length(indices);
    
    % First and last record of each experimental test.
    indices = [indices(1:end-1) indices(2:end) - 1; indices(end) size(nev_eventstrings, 1)];

    % Split the selected files per experimental test.
    for test_counter = 1:n_tests
        
        fprintf('Recording session #%02d\n', test_counter);
        new_dir = sprintf('session%02d\\', test_counter);
        
        try                
            
            curr_indices = indices(test_counter, :);
            time_limits  = nev_timestamps(curr_indices);
            
            mkdir([curr_dir new_dir]);
            Mat2NlxEV([curr_dir new_dir 'Events.nev'], 0, 2, curr_indices, [1 1 1 1 1 1], nev_timestamps, nev_eventids, nev_ttls, nev_extras, nev_eventstrings, nev_header);    
            
            for file_counter = 1:n_files
                curr_file = ncs_files{file_counter};
                [ncs_timestamps, ncs_channelnumbers, ncs_samplefrequencies, ncs_numberofvalidsamples, ncs_samples, ncs_header] = Nlx2MatCSC([curr_dir curr_file], [1 1 1 1 1], 1, 4, time_limits);           
                Mat2NlxCSC([curr_dir new_dir curr_file], 0, 1, [], [1 1 1 1 1 1], ncs_timestamps, ncs_channelnumbers, ncs_samplefrequencies, ncs_numberofvalidsamples, ncs_samples, ncs_header);
                fprintf('File %s has been processed.\n', curr_file);
            end
            
        catch err            
            disp(['Error identifier: ' err.identifier]);            
        end
        
    end

end
