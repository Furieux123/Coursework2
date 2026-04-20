function temp_monitor(arduinoObj, runDuration)
%   TEMP_MONITOR Real-time temperature monitoring with LED indicators
%   temp_monitor(arduinoObj, runDuration) monitors temperature using the connected Arduino and displays status via LEDs based on comfort range.
%   
%   Inputs:
%       arduinoObj - Arduino object created with arduino() function
%       runDuration - Duration to run monitoring in seconds (use inf for continuous)
%
%   LED Indicators:
%       Green (D2): Constant ON when temperature is in comfort range (18-24°C)
%       Yellow (D3): Blinking at 0.5s intervals when temperature < 18°C
%       Red (D4): Blinking at 0.25s intervals when temperature > 24°C
%
%   The function creates a live plot of temperature vs time that updates in real-time during monitoring.  


% Constants
TC = 0.01; % Temperature coefficient (V/°C)
V0C = 0.5; % Voltage at 0°C (V)
COMFORT_MIN = 18; % Minimum comfort temperature (°C)
COMFORT_MAX = 24; % Maximum comfort temperature (°C)
SAMPLE_INTERVAL = 1; % Sampling interval (seconds)

% LED pin definitions
greenPin = 'D2';
yelloPin = 'D3';
redPin = 'D4';

% Blink timing
yellow_blink_period = 0.5;  % seconds
red_blink_period = 0.25;    % seconds

% Initialize
startTime = tic;
elapsedTime = 0;
sampleCount = 0;

% Initialize data arrays (preallocate for efficiency)
if isinf(runDuration)
    % Continuous monitoring mode: Initial allocation of 100, with subsequent dynamic scaling
    maxSamples = 100;
    timeHistory = zeros(1, maxSamples);
    tempHistory = zeros(1, maxSamples);
else
    % Limited duration: Normal pre-allocation
    maxSamples = ceil(runDuration / SAMPLE_INTERVAL) + 10;
    timeHistory = zeros(1, maxSamples);
    tempHistory = zeros(1, maxSamples);
end
timeHistory = zeros(1, maxSamples);
tempHistory = zeros(1, maxSamples);

% Create figure for live plotting
figureHandle = figure('Name', 'Live Temperature Monitor', 'NumberTitle', 'off');
plotHandle = plot(NaN, NaN, 'b-', 'LineWidth', 2);
xlabel('Time (seconds)');
ylabel('Temperature (°C)');
title('Real-Time Temperature Monitoring');
grid on;
hold on;

% Add comfort range lines
yline(COMFORT_MIN, 'g--', 'Min Comfort');
yline(COMFORT_MAX, 'g--', 'Max Comfort');

% Initialize all LEDs to OFF
writeDigitalPin(arduinoObj, greenPin, 0);
writeDigitalPin(arduinoObj, yelloPin, 0);
writeDigitalPin(arduinoObj, redPin, 0);

%% Main monitoring loop
lastYellowToggle = 0;
lastRedToggle = 0;
yellowState = 0;
redState = 0;

while elapsedTime < runDuration
    % Read current temperature
    voltage = readVoltage(arduinoObj, 'A0');
    currentTemp = (voltage - V0C) / TC;
    
    % Update data arrays
    sampleCount = sampleCount + 1;
    elapsedTime = toc(startTime);
    timeHistory(sampleCount) = elapsedTime;
    tempHistory(sampleCount) = currentTemp;
    
    % Update plot
    set(plotHandle, 'XData', timeHistory(1:sampleCount), 'YData', tempHistory(1:sampleCount));
    xlim([0 max(elapsedTime + 5, 10)]);
    ylim([min(tempHistory(1:sampleCount)) - 2, max(tempHistory(1:sampleCount)) + 2]);
    drawnow;
    
    % LED Control Logic
    if currentTemp >= COMFORT_MIN && currentTemp <= COMFORT_MAX
        % In comfort range - Green constant ON, others OFF
        writeDigitalPin(arduinoObj, greenPin, 1);
        writeDigitalPin(arduinoObj, yelloPin, 0);
        writeDigitalPin(arduinoObj, redPin, 0);
        
    elseif currentTemp < COMFORT_MIN
        % Below range - Yellow blinking at 0.5s, others OFF
        writeDigitalPin(arduinoObj, greenPin, 0);
        writeDigitalPin(arduinoObj, redPin, 0);
        
        % Handle yellow blinking
        if elapsedTime - lastYellowToggle >= yellow_blink_period
            yellowState = ~yellowState;
            writeDigitalPin(arduinoObj, yelloPin, yellowState);
            lastYellowToggle = elapsedTime;
        end
        
    else % currentTemp > COMFORT_MAX
        % Above range - Red blinking at 0.25s, others OFF
        writeDigitalPin(arduinoObj, greenPin, 0);
        writeDigitalPin(arduinoObj, yelloPin, 0);
        
        % Handle red blinking
        if elapsedTime - lastRedToggle >= red_blink_period
            redState = ~redState;
            writeDigitalPin(arduinoObj, redPin, redState);
            lastRedToggle = elapsedTime;
        end
    end
    
    % Wait for next sample
    pause(SAMPLE_INTERVAL);
end

% Cleanup
% Turn off all LEDs
writeDigitalPin(arduinoObj, greenPin, 0);
writeDigitalPin(arduinoObj, yelloPin, 0);
writeDigitalPin(arduinoObj, redPin, 0);

% Save final plot
saveas(figureHandle, 'live_temperature_monitor.png');
end