function trial_info = align_licks_in_time(trial_info)

    figure;
    
    % Displayed time spread, sec.
    x_range = [0 6.0];
    
    for trial_no = 1:length(trial_info)

        % Trial initiation.
        trial_start = trial_info(trial_no).start{2};
        
        % Lick timings in date format.
        left_licks  = trial_info(trial_no).left_licks_clock;
        right_licks = trial_info(trial_no).right_licks_clock;
        
        % Lick timings relative to trial initiation, sec.
        left_licks  = align_licks(left_licks, trial_start);
        right_licks = align_licks(right_licks, trial_start);
        
        trial_info(trial_no).left_licks_aligned  = left_licks;
        trial_info(trial_no).right_licks_aligned = right_licks;
        
        % Use different colors for rewarded trials.
        if trial_info(trial_no).rewarded
            marker = '.r';
        else
            marker = '.b';
        end
        
        % Display lick events separately for each spout and trial.
        if isempty(left_licks)
            subplot(1, 2, 1), plot(mean(x_range), trial_no, '.w'), hold on;
        else
            subplot(1, 2, 1), plot(left_licks, trial_no * ones(1, length(left_licks)), marker), hold on;
        end
        
        if isempty(right_licks)
            subplot(1, 2, 1), plot(mean(x_range), trial_no, '.w'), hold on;
        else
            subplot(1, 2, 2), plot(right_licks, trial_no * ones(1, length(right_licks)), marker), hold on;
        end
        
        subplot(1, 2, 1), xlim(x_range), xlabel('time, sec'), ylabel('trial no.'), title('Spout #1 (red - rewarded)');
        subplot(1, 2, 2), xlim(x_range), xlabel('time, sec'), ylabel('trial no.'), title('Spout #2 (red - rewarded)');
        
    end

end

function aligned = align_licks(licks, trial_start)

    aligned = [];
    n_licks = size(licks, 1);
    
    for lick_no = 1:n_licks
        aligned(end + 1) = etime(licks(lick_no, :), trial_start);
    end
    
end
