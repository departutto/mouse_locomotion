[filename, pathname] = uigetfile('*.nev', 'Select Events file (*.nev)');
if ~filename
    clear filename pathname;
    return;
else
    fprintf('Events file: %s%s\n', pathname, filename);
end

[timestamps, ttls] = Nlx2MatEV([pathname filename], [1 0 1 0 0], 0, 1, 1);
time0 = timestamps(1);
timestamps = (timestamps - time0) / 10 ^ 6;
photocell_events = bitand(ttls, 3);
event_descriptors = bitshift(ttls, -2);
consolidated = [timestamps' event_descriptors' photocell_events'];

clear filename pathname timestamps ttls photocell_events event_descriptors;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

headers_start = find(consolidated(:, 2) == 63 & consolidated(:, 3) == 2); 
headers_stop = find(consolidated(:, 2) == 63 & consolidated(:, 3) == 1);

n = min([length(headers_start) length(headers_stop)]);
misaligned = find(headers_stop(1:n) - headers_start(1:n) ~= 6, 1);
if ~isempty(misaligned)
    disp(['Header start and stop indices = ' num2str(headers_start(misaligned)) ' x ' num2str(headers_stop(misaligned))]);    
    return;
end

corrupted = find(consolidated(headers_start + 1, 2)      |  consolidated(headers_start + 1, 3)      | ...
                 consolidated(headers_start + 2, 2) ~= 8 |  consolidated(headers_start + 2, 3) ~= 1 | ...
                 consolidated(headers_start + 3, 2)      |  consolidated(headers_start + 3, 3)      | ...
               (~consolidated(headers_start + 4, 2)      & ~consolidated(headers_start + 4, 3))     | ...
                 consolidated(headers_start + 7, 2)      |  consolidated(headers_start + 7, 3), 1);
if ~isempty(corrupted)
    disp(['Header start and stop indices = ' num2str(headers_start(corrupted)) ' x ' num2str(headers_stop(corrupted))])
    return;
end

disp(['N(Header start and stop entries) = ' num2str(length(headers_start)) ' x ' num2str(length(headers_stop))]);
if length(headers_start) ~= length(headers_stop)
    disp('Unmatched number of the header start and stop entries!');
    return;
end

clear n misaligned corrupted; 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

trials = struct([]);
timestamps = [headers_start + 8 [headers_start(2:end) - 1; size(consolidated, 1)]];

for trial_no = 1:length(headers_start)
    
    index_start = headers_start(trial_no);
    index_stop = headers_stop(trial_no);
    
    trials(trial_no).indices = [consolidated(index_start, 1) consolidated(index_stop, 1)];
    trials(trial_no).onset = consolidated(index_start, 1);
    trials(trial_no).condition = bitor(bitshift(consolidated(index_start + 4, 2), 2), consolidated(index_start + 4, 3));
    trials(trial_no).photoevents = [];
    
    indices = timestamps(trial_no, 1):timestamps(trial_no, 2);
    selected = consolidated(indices, 2) == 0 & consolidated(indices, 3) == 2;
    photoevents = consolidated(indices(selected), 1);
    if isempty(photoevents)
        continue;
    end
    
    for photoevent_no = 1:length(photoevents)
        if isempty(trials(trial_no).photoevents) || photoevents(photoevent_no) - trials(trial_no).photoevents(end) > 0.25
            trials(trial_no).photoevents(end + 1) = photoevents(photoevent_no);
        end
    end
    
    if length(trials(trial_no).photoevents) ~= 2
        fprintf('Trial #%d: N(photocell events) = %d.\n', trial_no, length(trials(trial_no).photoevents));        
        if length(trials(trial_no).photoevents) > 2
            trials(trial_no).photoevents = trials(trial_no).photoevents(1:2);
            disp('Reduced to the first two photocell events!');
        end
    end
    
end

clear timestamps index_start index_stop indices selected photoevents photoevent_no headers_start headers_stop;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

conditions = [];
for trial_no = 1:length(trials)
    conditions(end + 1) = trials(trial_no).condition;
end

n_conditions = length(unique(conditions));
n_occurences = zeros(1, n_conditions);
disp(['Unique conditions = [' num2str(unique(conditions)) ']']);

for counter = 1:length(trials)
    curr_condition = trials(counter).condition;
    n_occurences(curr_condition) = n_occurences(curr_condition) + 1;
end

figure;
plot(n_occurences, '-g');
xlabel('condition no.'), ylabel('#');

clear curr_condition n_conditions n_occurences counter;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

stim_duration = [];
for trial_no = 1:length(trials)
    if length(trials(trial_no).photoevents) == 2
        stim_duration(end + 1) = trials(trial_no).photoevents(2) - trials(trial_no).photoevents(1);
    else
        stim_duration(end + 1) = -1;
    end
end

figure;
plot(stim_duration, '-r');
xlabel('trial no.'), ylabel('stimulus duration, sec');
title(['N = ' num2str(length(stim_duration)) ' points']);

clear stim_duration;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

iti_duration = [];
for trial_no = 2:length(trials)
    if ~isempty(trials(trial_no - 1).photoevents) && ~isempty(trials(trial_no).photoevents)
        iti_duration(end + 1) = trials(trial_no).photoevents(1) - trials(trial_no - 1).photoevents(end);
    else
        iti_duration(end + 1) = -1;
    end
end

figure;
plot(iti_duration, '-b');
xlabel('trial no.'), ylabel('inter-trial interval, sec');
title(['N = ' num2str(length(iti_duration)) ' points']);

clear trial_no iti_duration;
