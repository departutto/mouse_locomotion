function [grating, gaussian] = generate_grating(varargin)

    % Image size, pixels.
    img_size = 1200;
    
    % Wavelength, pixels / cycle.
    lambda = 400;
    
    % Initial phase, radians.
    phase = 0.0 / 180.0 * pi;
    
    % Grating orientation, radians.
    angle = 120.0 / 180.0 * pi;
    
    % Standard deviation for the gaussian envelope relative to the image size.
    sigma = 0.15; % in pixels - 20.0 / img_size;
    
    % Values in the gaussian envelope below this threshold are of the same
    % color as the background.
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
    
    % Gaussian envelope.
    gaussian = exp(-(xm .^ 2 + ym .^ 2) ./ (2 * sigma ^ 2));        
    
    % Convolve the gaussian envelope with a generated grating. The range of
    % values is between -1 and +1.
    grating  = gaussian .* grating;
    
    % Use a grayscale color scheme (0 - black, 255 white).
    grating  = round(255 / 2.0 * (grating + 1)); 
   
    % Set the color of the pixels outside the aperture to the color of the background.
    aperture = gaussian < trim_thr;
    grating(aperture) = bkg_color;
    grating = uint8(grating);
        
    % Show the gaussian envelope and the grating.
    figure;
    subplot(1, 2, 1), imagesc(gaussian, [-1 1]), colormap gray(256), axis off, axis image;
    subplot(1, 2, 2), imshow(grating), axis off, axis image; 
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    if ~isempty(varargin)
        imwrite(grating, varargin{1}, 'jpg');
    end
        
end
