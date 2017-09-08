function trial_info = align_licks_in_time(trial_info)

    for trial_no = 1:length(trial_info)

        trial_start = trial_info(trial_no).start{2};
        left_licks  = trial_info(trial_no).left_licks_clock;
        right_licks = trial_info(trial_no).right_licks_clock;
        
        trial_info(trial_no).left_licks_aligned  = align_licks(left_licks, trial_start);
        trial_info(trial_no).right_licks_aligned = align_licks(right_licks, trial_start);
        
    end

end

function aligned = align_licks(licks, trial_start)

    aligned = [];
    n_licks = size(licks, 1);
    
    for lick_no = 1:n_licks
        aligned(end + 1) = etime(licks(lick_no, :), trial_start);
    end
    
end
