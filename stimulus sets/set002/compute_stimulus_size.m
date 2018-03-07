% Monitor: Dell UltraSharp 27'' (U2715H).
% Resolution: 2560 x 1440 pixels.
% Dimensions: 59.77 x 33.62 cm.

angle_deg = 30; % degrees
distance  = 34; % distance from the eye to the screen, cm.

angle_rad  = angle_deg / 180 * pi;
stim_size1 = 2 * distance * sin(angle_rad / 2.0) / cos(angle_rad / 2.0);
stim_size2 = 2 * distance * sin(angle_rad) / (1 + cos(angle_rad));
disp(['Distance to the screen = ' num2str(distance) ' cm']);
disp(['Stimulus size = ' num2str(angle_deg) ' degrees']);
disp(['Stimulus size = ' num2str(stim_size1) ' / ' num2str(stim_size2) ' cm']);

error1 = 0.5 * distance * stim_size1 - 0.5 * (distance * distance + stim_size1 * stim_size1 / 4) * sin(angle_rad);
error2 = 0.5 * distance * stim_size2 - 0.5 * (distance * distance + stim_size2 * stim_size2 / 4) * sin(angle_rad);
disp(['Computation error = ' num2str(error1) ' / ' num2str(error1)]);

stim_width  = round(stim_size1 * 2560 / 59.77); % pixels 
stim_height = round(stim_size1 * 1440 / 33.62); % pixels
disp(['Stimulus width and height = ' num2str(stim_width) ' x ' num2str(stim_height) ' pixels']);