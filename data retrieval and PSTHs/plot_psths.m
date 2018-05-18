function [psths, conditions, locomotion] = plot_psths(varargin)

    if isempty(varargin)
        fprintf('Exit code #1.\n');
        return;
    else 
        filename = varargin{1};
        bins = -0.3:0.01:0.6; % seconds.
        bin_width = 0.01;     % seconds.
        photoevent_nums = 1;  % first photoevent.
    end
    
    if isempty(who('-file', filename, 'trials'))
        fprintf('Exit code #2.\n');
        return;
    else
        load(filename);
    end
    
    if length(varargin) > 1
        bins = varargin{2};
    end
    
    if size(bins, 2) == 1 || ~isnumeric(bins) || any(bins(1:end - 1) >= bins(2:end))
        fprintf('Exit code #3.\n');
        return;
    end

    if length(varargin) > 2
        bin_width = varargin{3};
    end
    
    if length(bin_width) ~= 1 || bin_width <= 0 || bin_width > bins(end) - bins(1)
        fprintf('Exit code #4.\n');
        return;
    end
    
    if length(varargin) > 3
        photoevent_nums = varargin{4};
    end
    
    if ~isnumeric(photoevent_nums) || min(photoevent_nums) < 1
        fprintf('Exit code #5.\n');
        return;
    end
    
    if length(varargin) > 4
        locomotion_fun = varargin{5};
    else
        locomotion_fun = @(x) false;
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Number of trials.
    n_trials = length(trials);
    fprintf('Number of trials = %d\n', n_trials);
    
    % Make sure that the number of photoevents in each non-corrupted trial
    % is the same across trials. 
    n_photoevents = [];
    for counter = 1:n_trials
        if isfield(trials, 'corrupted')
            n_photoevents(end + 1, :) = [trials(counter).corrupted length(trials(counter).photoevents)];
        else
            n_photoevents(end + 1, :) = [0 length(trials(counter).photoevents)];
        end
    end
    non_corrupted = n_photoevents(:, 1) == 0;
    n_unique_photoevents = unique(n_photoevents(non_corrupted, 2));
    
    % Quit if the number of photoevents differs across trials.
    if length(n_unique_photoevents) ~= 1
        fprintf('Exit code #6.\n');
        return;
    else
        fprintf('Number of photoevents in a trial = %d\n', n_unique_photoevents);
    end
    
    % Stimulus conditions.
    conditions = [];
    
    % Indicates whether the animal was running or standing still in a trial.
    locomotion = [];
    
    % Peri-stimulus time histograms (PSTHs) aligned to each photoevent.
    psths = {};
    for counter = 1:n_unique_photoevents
        psths{counter} = [];
    end
    
    for trial_no = 1:n_trials

        % Skip corrupted trials.
        if isfield(trials, 'corrupted') && trials(trial_no).corrupted == 1
            continue;
        end
        
        conditions(end + 1) = trials(trial_no).condition;
        locomotion(end + 1) = locomotion_fun(trials(trial_no));
        
        % For each photoevent construct a PSTH aligned to that event.
        for photoevent_no = 1:n_unique_photoevents
            
            % Spike timestamps aligned to the current photocell event, sec.
            spikes = trials(trial_no).spikes{photoevent_no} - trials(trial_no).photoevents(photoevent_no);
            
            if isempty(spikes)
                psths{photoevent_no}(end + 1, :) = zeros(1, length(bins));
            else
                % Add a PSTH aligned to the current photocell event, spikes/sec.
                psths{photoevent_no}(end + 1, :) = (1.0 / bin_width) * histc(spikes, bins);
            end
            
        end
        
    end
    
    % Number of unique stimulus conditions.
    n_unique_conditions = length(unique(conditions));
    
    % Number of rows and columns in the final PSTHs plot.
    n_rows = round(sqrt(n_unique_conditions));
    if n_rows * n_rows == n_unique_conditions
        n_cols = n_rows;
    else
        n_cols = n_rows + 1;
    end
    
    % Plot PSTHs for each specified photoevent.
    figure;
    colors = ['b', 'r', 'g', 'k', 'm', 'y', 'c'];
    for counter = 1:length(photoevent_nums)
        
        % Current photoevent number.
        current_photoevent = photoevent_nums(counter);
        
        % Current stimulus condition.
        current_condition = 0;
        
        % Color to plot PSTHs.
        current_color = colors(counter);
        
        for row = 1:n_rows
            for col = 1:n_cols
                
                current_condition = current_condition + 1;
                selection = conditions == current_condition;
                selection = psths{current_photoevent}(selection, :);
                n_selected = size(selection, 1);
                
                % Proceed to the next condition when no data are available.
                if isempty(selection)
                    continue;
                end
                
                if n_selected > 1
                    avg_psth = mean(selection);
                else
                    avg_psth = selection;
                end
                
                subplot(n_rows, n_cols, current_condition), plot(avg_psth, current_color), hold on;
                xlim([1 size(avg_psth, 2) - 1]), set(gca, 'XTick', []);
                title(['#' num2str(current_condition) ' (N = ' num2str(n_selected) ')']);
                
                if col == 1
                    ylabel('response, Hz');
                end
                
                if current_condition + n_cols > n_unique_conditions
                    xlabel('time');
                end
                
            end
        end
        
    end
    
    saveas(gcf, [filename(1:end-4)], 'jpg');
    close(gcf);
    
end
