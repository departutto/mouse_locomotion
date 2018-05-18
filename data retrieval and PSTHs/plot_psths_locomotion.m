function plot_psths_locomotion(filename)

    bins = -0.3:0.01:0.6;      % seconds.
	bin_width = 0.01;          % seconds.
	photoevent_nums = [1, 3];  % first photoevent.   
    
    % Number of rows and columns in the final figure.
    n_rows = 2;
    n_cols = 2;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    [psths, conditions, locomotion] = plot_psths(filename, bins, bin_width, photoevent_nums, @control_for_locomotion);   
    [adapter_stationary, test_stationary] = avg_psths(psths{1}, psths{3}, conditions, ~locomotion);
    [adapter_locomotion, test_locomotion] = avg_psths(psths{1}, psths{3}, conditions, locomotion);
    
    % Analyze stimulus conditions containing at least one trial.
    stationary_conds = find(adapter_stationary(:, 1) >= 0.0);
    locomotion_conds = find(adapter_locomotion(:, 1) >= 0.0);
    
    % Dimensionality of the PSTHs in time domain.
    time_dim = size(psths{1}, 2);
    
    %---------------------------------------------------|
    %   |          T E S T          |      T E S T      | 
    %-------------------------------|-------------------|
    % A | #  A   B   C   D   E   F  | A  B  C  D  E  F  |
    % D | A  AA  AB  AC  AD  AE  AF | 01 02 03 04 05 06 | \
    % A | B  BA  BB  BC  BD  BE  BF | 07 08 09 10 11 12 |  \
    % P | C  CA  CB  CC  CD  CE  CF | 13 14 15 16 17 18 |   \
    % T | D  DA  DB  DC  DD  DE  DF | 19 20 21 22 23 24 |   / STIMULUS CONDITIONS
    % E | E  EA  EB  EC  ED  EE  EF | 25 26 27 28 29 30 |  /
    % R | F  FA  FB  FC  FD  FE  FF | 31 32 33 34 35 36 | /
    %-------------------------------|-------------------|
    
    % Stimulus conditions with stimulus repetitions.
    rep_trials = [1 8 15 22 29 36];
    
    % Stimulus conditions with stimulus alternations.
    alt_trials = [2 3 4 5 6 7 9 10 11 12 13 14 16 17 18 19 20 21 23 24 25 26 27 28 30 31 32 33 34 35];
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
    
    % Response to the adapter and test stimuli in repetition trials without
    % locomotion.
    analyzed_conds = intersect(rep_trials, stationary_conds);    
    rep_adapter_stationary = aggregate_fun(adapter_stationary(analyzed_conds, :), time_dim);
    rep_test_stationary = aggregate_fun(test_stationary(analyzed_conds, :), time_dim);
    
    % Response to the adapter and test stimuli in repetition trials with 
    % locomotion.
    analyzed_conds = intersect(rep_trials, locomotion_conds);    
    rep_adapter_locomotion = aggregate_fun(adapter_locomotion(analyzed_conds, :), time_dim);
    rep_test_locomotion = aggregate_fun(test_locomotion(analyzed_conds, :), time_dim);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
    
    % Response to the test stimulus in alternation trials without locomotion.
    analyzed_conds = intersect(alt_trials, stationary_conds);
    alt_test_stationary = aggregate_fun(test_stationary(analyzed_conds, :), time_dim);
    
    % Response to the test stimulus in alternation trials with locomotion.
    analyzed_conds = intersect(alt_trials, locomotion_conds);
    alt_test_locomotion = aggregate_fun(test_locomotion(analyzed_conds, :), time_dim);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    figure;
    
    subplot(n_rows, n_cols, 1), hold on;
    plot(rep_adapter_stationary, '-b');
    plot(rep_test_stationary, '-r');
    plot([30.5 30.5], get(gca, 'YLim'), '--k');
    plot([60.5 60.5], get(gca, 'YLim'), '--k');
    xlim([1 time_dim - 1]), set(gca, 'XTick', []);
    legend('Adapter', 'Test', 'Location', 'SouthEast', 'Orientation', 'Horizontal');
    xlabel('time'), ylabel('response, Hz'), title('Stationary: Rep trials');
    
    subplot(n_rows, n_cols, 3), hold on;
    plot(rep_adapter_locomotion, '-b');
    plot(rep_test_locomotion, '-r');
    plot([30.5 30.5], get(gca, 'YLim'), '--k');
    plot([60.5 60.5], get(gca, 'YLim'), '--k');
    xlim([1 time_dim - 1]), set(gca, 'XTick', []);
    xlabel('time'), ylabel('response, Hz'), title('Locomotion: Rep trials');
    
    subplot(n_rows, n_cols, 2), hold on;
    plot(rep_test_stationary, '-b');
    plot(alt_test_stationary, '-r');   
    plot([30.5 30.5], get(gca, 'YLim'), '--k');
    plot([60.5 60.5], get(gca, 'YLim'), '--k');
    legend('Rep', 'Alt', 'Location', 'SouthEast', 'Orientation', 'Horizontal');
    xlim([1 time_dim - 1]), set(gca, 'XTick', []);    
    xlabel('time'), ylabel('response, Hz'), title('Stationary: Test stim');
    
    subplot(n_rows, n_cols, 4), hold on;
    plot(rep_test_locomotion, '-b');
    plot(alt_test_locomotion, '-r');
    plot([30.5 30.5], get(gca, 'YLim'), '--k');
    plot([60.5 60.5], get(gca, 'YLim'), '--k');
    xlim([1 time_dim - 1]), set(gca, 'XTick', []);
    xlabel('time'), ylabel('response, Hz'), title('Locomotion: Test stim');
    
    saveas(gcf, [filename(1:end-4) '-adaptation'], 'jpg');
    close(gcf);
    
end

function is_running = control_for_locomotion(single_trial)
    
    % Velocity threshold to detect locomotion, cm/sec.
    threshold = 1.0;
    
    % Index of the adapter stimulus onset in the locomotion signal.
    adapter_onset = 90 + 1;
    
    % Index of the test stimulus offset in the locomotion signal. Remember
    % that duration of the adapter stimulus, inter-stimulus interval and
    % test stimulus is 300 msec. Given the sampling frequency of 100 Hz,
    % 300 msec corresponds to 30 data points in the locomotion signal.
    test_offset = adapter_onset + 30 + 30 + 30;
     
    is_running = mean(single_trial.velocity{1}(adapter_onset:test_offset)) > threshold;
    
end

function result = aggregate_fun(values, dim)

    if isempty(values)
        result = -1 * ones(1, dim);
    elseif size(values, 1) == 1
        result = values;
    else
        result = mean(values);
    end
    
end

function [adapter_avg, test_avg] = avg_psths(adapter_stim, test_stim, conditions, is_included)

    % Average PSTHs per stimulus condition.
    adapter_avg = [];
    test_avg    = [];
    
    % Number of different stimulus conditions.
    n_conditions = length(unique(conditions));
    
    % Dimensionality of the generated average PSTHs in time domain. 
    time_dim = size(adapter_stim, 2);
    
    for counter = 1:n_conditions
        
        % Select stimulus presentations of a particular stimulus condition
        % as specified by variable 'counter'.
        selection = conditions == counter & is_included;       
        
        % Generate average PSTHs separately for the adapter and test
        % stimulus presentations for the analyzed stimulus condition.
        adapter_avg(end + 1, :) = aggregate_fun(adapter_stim(selection, :), time_dim);
      	test_avg(end + 1, :)    = aggregate_fun(test_stim(selection, :), time_dim);
            
    end
    
end
