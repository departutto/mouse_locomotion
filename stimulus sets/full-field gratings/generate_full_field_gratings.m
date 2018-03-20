function generate_full_field_gratings(destination)

    dist      = 35.0;                                                      % distance to the screen, cm
    edge      = 59.77;                                                     % screen longest edge, cm
    max_angle = asin(4 * dist * edge / (edge * edge + 4 * dist * dist));   % viewing angle, radians
    sp_freq   = 0.06;                                                      % spatial frequency, cycles per degree
    
    max_angle = max_angle / pi * 180;
    if dist < edge / 2
        max_angle = 180 - max_angle;
    end
    
    phase    = 0;                                                          % initial phase of the gratings, degrees
    n_cycles = sp_freq * max_angle;                                        % number of cycles 
    
    fprintf('Viewing angle: %.2f\n', max_angle);
    fprintf('Number of cycles: %.2f\n', n_cycles);
    fprintf('Spatial frequency: %.2f\n', sp_freq);
     
    screen_width  = 1920;                                                  % pixels
    screen_height = 1200;                                                  % pixels    
    
    stimulus_counter = 1;
    for angle = 0:30:150
        filename = [destination num2str(stimulus_counter)];
        generate_single_grating(screen_width, screen_height, phase, angle, n_cycles, filename);
        stimulus_counter = stimulus_counter + 1;
    end

end

function generate_single_grating(screen_width, screen_height, phase, angle, n_cycles, filename)

    phase    = phase / 180 * pi;                                           % radians
    angle    = angle / 180 * pi;                                           % radians

    max_dim  = max([screen_width, screen_height]);                         % pixels
    min_dim  = min([screen_width, screen_height]);                         % pixels
    img_size = max_dim;
    margin   = round((max_dim - min_dim) / 2.0);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    x        = (0:(img_size - 1)) / (img_size - 1) - 0.5;
    [x, y]   = meshgrid(x, x);
    coors    = x * cos(angle) + y * sin(angle);
    coors    = 2 * pi * n_cycles * coors;
    grating  = uint8(255.0 * cos(coors + phase));
    grating  = grating((margin + 1):(img_size - margin), :);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    imwrite(grating, [filename '.jpg'], 'jpg');
    
end