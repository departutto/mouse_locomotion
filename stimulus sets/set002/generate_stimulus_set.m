function generate_stimulus_set

    img_size      = 780;  % pixels
    stimulus_size = 30;   % degrees
    spatial_freq  = 0.2;  % cycles per degree
    n_cycles      = stimulus_size * spatial_freq;
    angles        = [0 30 60 90 120 150]; % degrees    
    
    for counter = 1:length(angles)
        generate_grating(img_size, n_cycles, angles(counter), num2str(counter));
    end
    
end

function generate_grating(img_size, n_cycles, angle, filename)

    % Wavelength, pixels / cycle.
    lambda = img_size / n_cycles;
    
    % Initial phase, radians.
    phase = 90.0 / 180.0 * pi;
    
    % Grating orientation, radians.
    angle = angle / 180.0 * pi;
    
    % Standard deviation for the gaussian envelope relative to the image size.
    sigma = 0.15; 
    
    % Values in the envelope below which the pixels in the grating are set 
    % to the background color.
    trim_thr = 0.005;

    % Background color.
    bkg_color = 128;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Scale the future image to fit the range from -0.5 to 0.5. 
    x = (0:(img_size - 1)) / (img_size - 1) - 0.5;
    
    % Construct a grating.
    [xm, ym] = meshgrid(x, x);
    coors    = xm * cos(angle) + ym * sin(angle);
    coors    = 2 * pi * img_size / lambda * coors;
    grating  = sin(coors + phase);
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % Choose one of the two envelopes.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Gaussian envelope.
    % envelope = exp(-(xm .^ 2 + ym .^ 2) ./ (2 * sigma ^ 2));   
    
    % Circular envelope.
    envelope = sqrt(xm .^ 2 + ym .^ 2) <= 0.5;
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    % Convolve the envelope with a generated grating.
    grating  = envelope .* grating;
    
    % Use a grayscale color scheme (0 - black, 255 white).
    grating  = round(255 / 2.0 * (grating + 1)); 
   
    % Set the color of the pixels outside the aperture to the color of the background.
    aperture = envelope < trim_thr;
    grating(aperture) = bkg_color;
    grating = uint8(grating);
        
    % Show the envelope and the grating.
    % figure;
    % subplot(1, 2, 1), imagesc(envelope, [-1 1]), colormap gray(256), axis off, axis image;
    % subplot(1, 2, 2), imshow(grating), axis off, axis image; 
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    fprintf('%s', filename);
    if ~isempty(filename)
        imwrite(grating, [filename '.jpg'], 'jpg');
    end
        
end
