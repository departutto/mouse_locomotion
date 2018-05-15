function incorporate_speed_signal(varargin)

    % Number of stimulus presentations per trial. When no input is
    % specified, the default value is 2.
    if ~isempty(varargin) && isnumeric(varargin{1}) && varargin{1} >= 1
        N_STIMULI_PER_TRIAL = varargin{1};
    else
        N_STIMULI_PER_TRIAL = 2;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    [mat_filename, mat_pathname] = uigetfile('*.mat', 'File with variable ''trials'' (*.mat)');
    
    % Quit if no file is selected.
    if ~mat_filename  
        fprintf('Exit code #1.\n'), return;       
    end
    
    mat_fullname = fullfile(mat_pathname, mat_filename);   
    
    % Quit if the selected file does not contain variable 'trials'.
    if isempty(who('-file', mat_fullname, 'trials'))
        fprintf('Exit code #2.\n'), return;  
    end
    
    load(mat_fullname);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    [m_filename, m_pathname] = uigetfile('*.m', 'File with the locomotion data (*.m)');
    
    % Quit if no file is selected.
    if ~m_filename
        fprintf('Exit code #3.\n'), return;  
    end
    
    try
        m_fullname = fullfile(m_pathname, m_filename);
        run(m_fullname);
	catch err
        fprintf('Exit code #4.\n'), return;  
    end
    
    % Quit if the selected file does not specify structure 'stimulus'
    % (locomotion signal per stimulus presentation), or the uploaded
    % structure 'stimulus' does not have field 'velocity'.
    if ~exist('stimulus', 'var') || ~isfield(stimulus, 'velocity')
        fprintf('Exit code #5.\n'), return;  
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    n_trials = length(trials);
    n_stimuli = length(stimulus);
    fprintf('Number of trials x Number of stimulus presentations = %d x %d\n', n_trials, n_stimuli);
    
    if N_STIMULI_PER_TRIAL * n_trials ~= n_stimuli
        fprintf('The number of trials does not match the number of stimulus presentations.\n');
        return;
    end    
    
    % Combine the locomotion data together with stimulus presentations.
    stimulus_no = 0;
    for trial_no = 1:n_trials
        for stim_in_trial = 1:N_STIMULI_PER_TRIAL
            stimulus_no = stimulus_no + 1;
            trials(trial_no).velocity{stim_in_trial} = stimulus(stimulus_no).velocity;
        end
    end
    
    % Save updated variable 'trials' in the file specified by the user (see above).
    save(mat_fullname, 'trials', '-append');
    
end
