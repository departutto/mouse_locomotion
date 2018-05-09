%% BLOCK NO. 1.
% FIRST, SPECIFY EXPERIMENT IDENTIFIER MADE UP OF 2 BYTES, AND THEN RUN THE
% CODE BLOCK BY BLOCK.

% List of the predefined experiment identifiers (first_byte x second_byte):
%   - mapping a receptive field (8 x 1); 
%   - current source density analysis (11 x 3);
%   - search test (8 x 2);
%   - adaptation test (12 x 0).
first_byte  = 12;
second_byte = 0;

% Minimum duration between any two detected neighbouring photocell events
% to be considered as the markers of stimulus onset and offset. Must be
% modified according to the experiment design. Modify with a GREAT CAUTION!
stimulus_separation_thr = 0.25;

% Number of photocell events per trial, as specified in the experiment design.
% Must be the same across the trials.
desired_n_photoevents = 4;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% BLOCK NO. 2. 

[filename, pathname] = uigetfile('*.nev', 'Select Events file (*.nev)');
if ~filename    % Quit if no file has been selected.
    clear filename pathname;
    return;
else
    fprintf('Events file: %s%s\n', pathname, filename);
end

% Retrieve raw data from the selected Events file. Function Nlx2MatEV is
% provided by Neuralynx (type "help Nlx2MatEV" for the documentation).
[timestamps, ttls] = Nlx2MatEV([pathname filename], [1 0 1 0 0], 0, 1, 1);

% Beginning of the recordings session: our time reference. 
time0 = timestamps(1);

% Align all the retrieved timestamps with respect to the time reference
% (time0), and then convert the aligned timestamps into sec.
timestamps = (timestamps - time0) / 10 ^ 6;

% Retrieve event descriptors (header start, experiment identifier, stimulus
% condition, header stop, trial stop) from the raw data.
event_descriptors = bitshift(ttls, -2);

% Retrieve photocell events from the raw data.
photocell_events = bitand(ttls, 3);

% Combine the retrieved data into one data structure for the sake of convenience.
consolidated = [timestamps' event_descriptors' photocell_events'];
fprintf('Block no. 2 was complete.\n');

% Delete unnecessary variables.
clear filename pathname timestamps ttls event_descriptors photocell_events;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% BLOCK NO. 3.

% Find indices of the records in the data structure 'consolidated' that
% correspond to the events of header start and header stop.
headers_start = find(consolidated(:, 2) == 63 & consolidated(:, 3) == 2); 
headers_stop = find(consolidated(:, 2) == 63 & consolidated(:, 3) == 1);

% Determine the number of trials.
n = min([length(headers_start) length(headers_stop)]);

% Identify trials with corrupted header organization. Note that the events
% of header start and header stop in correct trials must be separated by
% exactly 5 other records.
misaligned = find(headers_stop(1:n) - headers_start(1:n) ~= 6, 1);

% Trials with corrupted header organization must be manually corrected
% before one can proceed further. Alternatively, those trials can be instead
% removed from 'consolidated'. To remove record no. X from 'consolidated', 
% the following instruction can be used:
% >> consolidated = [consolidated(1:X - 1); consolidated(X + 1:end)];
if ~isempty(misaligned)
    fprintf('Situation #1: Header start and stop indices = %s x %s\n', num2str(headers_start(misaligned)), num2str(headers_stop(misaligned)));    
    return;
end

% Check header organization of the retrieved trials. The header organization 
% is specified in the function 'send_header_info' of the test scripts named 
% 'client_testname.m'.
corrupted = find(consolidated(headers_start + 1, 2)                | ...
                 consolidated(headers_start + 1, 3)                | ...
                 consolidated(headers_start + 2, 2) ~= first_byte  | ...
                 consolidated(headers_start + 2, 3) ~= second_byte | ... 
                 consolidated(headers_start + 3, 2)                | ...
                 consolidated(headers_start + 3, 3)                | ...
                 (~consolidated(headers_start + 4, 2) & ~consolidated(headers_start + 4, 3)) | ...
                 consolidated(headers_start + 7, 2) | consolidated(headers_start + 7, 3), 1);
             
% Trials with corrupted header organization must be manually corrected
% before one can proceed further. Alternatively, those trials can be instead
% removed from 'consolidated'. To remove record no. X from 'consolidated', 
% the following instruction can be used:
% >> consolidated = [consolidated(1:X - 1); consolidated(X + 1:end)];
if ~isempty(corrupted)
    fprintf('Situation #2: Header start and stop indices = %s x %s\n', num2str(headers_start(corrupted)), num2str(headers_stop(corrupted)));
    return;
end

% Display the number of header start and header stop entries. Those two numbers
% must be the same. Otherwise, there are two options to consider: (1) the 
% Events file was corrupted, or (2) data retrieval was done wrong.
fprintf('N(Header start and stop entries) = %s x %s\n', num2str(length(headers_start)), num2str(length(headers_stop)));
if length(headers_start) ~= length(headers_stop)
    disp('Unmatched number of the header start and stop entries!');
    return;
end

% Repeat executing this block followed by an appropriate correction of 
% 'consolidated' until you see the following message.
fprintf('Block no. 3 was complete.\n');

% Delete unnecessary variables.
clear n misaligned corrupted; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% BLOCK NO. 4.

trials = struct([]);
timestamps = [headers_start + 8 [headers_start(2:end) - 1; size(consolidated, 1)]];

for trial_no = 1:length(headers_start)
    
    % Index of the header start entry in 'consolidated' for the current trial.
    index_start = headers_start(trial_no);
    
	% Trial onset.
    trials(trial_no).onset = consolidated(index_start, 1);
    
    % Stimulus condition.
    trials(trial_no).condition = bitor(bitshift(consolidated(index_start + 4, 2), 2), consolidated(index_start + 4, 3));
    
    % List of the detected photocell events.
    trials(trial_no).photoevents = [];
    
    % Retrieve all detected photocell events for the current trial.
    indices = timestamps(trial_no, 1):timestamps(trial_no, 2);
    selected = consolidated(indices, 2) == 0 & consolidated(indices, 3) == 2;
    photoevents = consolidated(indices(selected), 1);
    if isempty(photoevents)
        continue;
    end
    
    % Leave only those photocell events that are separated from each other
    % by at least of 'stimulus_separation_thr' seconds.
    for photoevent_no = 1:length(photoevents)
        if isempty(trials(trial_no).photoevents) || photoevents(photoevent_no) - trials(trial_no).photoevents(end) > stimulus_separation_thr
            trials(trial_no).photoevents(end + 1) = photoevents(photoevent_no);
        end
    end
    
    % Display a message when the number of detected photocell events for the 
    % current trial differs from the desired one, as specified by the variable 
    % 'desired_n_photoevents' (see above).
    if length(trials(trial_no).photoevents) ~= desired_n_photoevents        
        fprintf('Trial no. %d has %d detected photocell events.\n', trial_no, length(trials(trial_no).photoevents));        
    end
    
    % If the number of detected photocell events for the current trials is
    % greater than the desired one, leave only the first 'desired_n_photoevents'
    % photocell events and remove the others.
    if length(trials(trial_no).photoevents) > desired_n_photoevents
        trials(trial_no).photoevents = trials(trial_no).photoevents(1:desired_n_photoevents);
    end
    
end

% Delete unnecessary variables.
clear timestamps index_start index_stop indices selected photoevents photoevent_no headers_start headers_stop;
fprintf('Block no. 4 was complete.\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% BLOCK NO. 5.

conditions = [];
for trial_no = 1:length(trials)
    conditions(end + 1) = trials(trial_no).condition;
end

n_conditions = length(unique(conditions));
n_occurences = zeros(1, n_conditions);

% Display unique identifiers of the retrieved stimulus conditions.
fprintf('Unique conditions = [%s]\n', num2str(unique(conditions)));

for counter = 1:length(trials)
    curr_condition = trials(counter).condition;
    n_occurences(curr_condition) = n_occurences(curr_condition) + 1;
end

% Plot identifiers of the retrieved stimulus conditions versus the number of 
% their occurences in the test.
figure, plot(n_occurences, '-g');
xlabel('condition no.'), ylabel('#');

clear conditions curr_condition n_conditions n_occurences counter;
fprintf('Block no. 5 was complete.\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% BLOCK NO. 6.

stim_duration = [];
for trial_no = 1:length(trials)
    
    % Compute duration of stimulus preentations while accounting for the
    % trial composition. The latter is assumed to be the same over the entire
    % recordings session.  
    
    if length(trials(trial_no).photoevents) == 2     % Single stimulus presentation per trial.
        stim_duration(end + 1) = trials(trial_no).photoevents(2) - trials(trial_no).photoevents(1);
        
    elseif length(trials(trial_no).photoevents) == 4 % Presentation of two stimuli separated by an inter-stimulus interval per trial.
        stim_duration(end + 1) = trials(trial_no).photoevents(2) - trials(trial_no).photoevents(1);
        stim_duration(end + 1) = trials(trial_no).photoevents(4) - trials(trial_no).photoevents(3);
        
    else                                             % Unknown trial composition.
        stim_duration(end + 1) = -1;
    end
    
end

% Plot duration of stimulus presentations over the entire recordings session.
figure, plot(stim_duration, '-r');
xlabel('trial no.'), ylabel('stimulus duration, sec');
title(['N = ' num2str(length(stim_duration)) ' data points']);

clear stim_duration;
fprintf('Block no. 6 was complete.\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% BLOCK NO. 7.

iti_duration = [];
for trial_no = 2:length(trials)
    
    % Compute duration of inter-trial intervals as the difference between
    % the last detected photocell event of a preceeding trial and the first
    % detected photocell event of a following trial over the entire
    % recordings session.
    if ~isempty(trials(trial_no - 1).photoevents) && ~isempty(trials(trial_no).photoevents)
        iti_duration(end + 1) = trials(trial_no).photoevents(1) - trials(trial_no - 1).photoevents(end);
    else 
        iti_duration(end + 1) = -1; % No photocell events in ether one or both neighbouring trials.
    end
end

% Plot duration of inter-trial intevals over the entire recordings session.
figure, plot(iti_duration, '-b');
xlabel('trial no.'), ylabel('inter-trial interval, sec');
title(['N = ' num2str(length(iti_duration)) ' data points']);

clear trial_no iti_duration; 
clear first_byte second_byte stimulus_separation_thr desired_n_photoevents;
fprintf('Block no. 7 was complete.\n');
