function temp_prediction(arduinoObj, runDuration)
%   TEMP_PREDICTION Temperature prediction and rate monitoring system
%   temp_prediction(arduinoObj, runDuration) monitors temperature rate of change and predicts future temperature values.
%
%   Inputs:
%       arduinoObj - Arduino object created with arduino() function
%       runDuration - Duration to run monitoring in seconds
%
%   Functionality:
%       - Calculates temperature change rate (°C/s) using derivative
%       - Predicts temperature in 5 minutes based on current rate
%       - Displays constant LEDs based on rate of change:
%           * Green: Stable temperature within comfort range (18-24°C)
%           * Red: Rate > +4°C/min (rapid increase)
%           * Yellow: Rate < -4°C/min (rapid decrease)
%
%   The function implements noise filtering using a moving average over medium-term samples to avoid spikes affecting rate calculations.


% Constants
TC = 0.01; % Temperature coefficient (V/°C)
V0C = 0.5; % Voltage at 0°C (V)
COMFORT_MIN = 18; % Minimum comfort temperature (°C)
COMFORT_MAX = 24; % Maximum comfort temperature (°C)
RATE_THRESHOLD = 4/60; % 4°C/min converted to °C/s (0.0667 °C/s)
SAMPLE_INTERVAL = 1; % Sampling interval (seconds)
PREDICTION_TIME = 300; % 5 minutes in seconds
FILTER_WINDOW = 10; % Moving average window for noise reduction

% LED pin definitions
greenPin = 'D2';
yellowPin = 'D3';
redPin = 'D4';

% Initialize
startTime = tic;
elapsedTime = 0;
sampleCount = 0;

% Data storage
maxSamples = ceil(runDuration / SAMPLE_INTERVAL) + 10;
tempHistory = zeros(1, maxSamples);
timeHistory = zeros(1, maxSamples);
filteredTemp = zeros(1, maxSamples);

% Initialize all LEDs to OFF
writeDigitalPin(arduinoObj, greenPin, 0);
writeDigitalPin(arduinoObj, yellowPin, 0);
writeDigitalPin(arduinoObj, redPin, 0);

% Main prediction loop
fprintf('elapsedTime  currentTemp  rateCpm  predictedTemp  status\n');
while elapsedTime < runDuration
    % Read current temperature
    voltage = readVoltage(arduinoObj, 'A0');
    currentTemp = (voltage - V0C) / TC;
    
    % Update data arrays
    sampleCount = sampleCount + 1;
    elapsedTime = toc(startTime);
    tempHistory(sampleCount) = currentTemp;
    timeHistory(sampleCount) = elapsedTime;
    
    % Apply moving average filter to reduce noise
    if sampleCount >= FILTER_WINDOW
        filteredTemp(sampleCount) = mean(tempHistory(sampleCount-FILTER_WINDOW+1:sampleCount));
    else
        filteredTemp(sampleCount) = currentTemp;
    end
    
    % Calculate rate of change (derivative)
    % Use medium-term difference to avoid noise spikes
    if sampleCount > 10
        % Calculate rate over last 10 seconds for stability
        dt = 10;  % Time difference in seconds
        dTemp = filteredTemp(sampleCount) - filteredTemp(max(sampleCount-10, 1));
        rateCps = dTemp / dt;  % Rate in °C/s
        rateCpm = rateCps * 60;  % Convert to °C/min for display
    else
        rateCps = 0;
        rateCpm = 0;
    end
    
    % Predict temperature in 5 minutes
    predictedTemp = currentTemp + (rateCps * PREDICTION_TIME);
    
    % Determine status and control LEDs
    if abs(rateCpm) <= 4 && currentTemp >= COMFORT_MIN && currentTemp <= COMFORT_MAX
        % Stable in comfort range - Green
        status = 'STABLE';
        writeDigitalPin(arduinoObj, greenPin, 1);
        writeDigitalPin(arduinoObj, yellowPin, 0);
        writeDigitalPin(arduinoObj, redPin, 0);
        
    elseif rateCpm > 4
        % Rapid increase - Red
        status = 'HEATING';
        writeDigitalPin(arduinoObj, greenPin, 0);
        writeDigitalPin(arduinoObj, yellowPin, 0);
        writeDigitalPin(arduinoObj, redPin, 1);
        
    elseif rateCpm < -4
        % Rapid decrease - Yellow
        status = 'COOLING';
        writeDigitalPin(arduinoObj, greenPin, 0);
        writeDigitalPin(arduinoObj, yellowPin, 1);
        writeDigitalPin(arduinoObj, redPin, 0);
        
    else
        % Outside comfort but stable rate - maintain previous or default to green
        status = 'ADJUSTING';
        writeDigitalPin(arduinoObj, greenPin, 1);
        writeDigitalPin(arduinoObj, yellowPin, 0);
        writeDigitalPin(arduinoObj, redPin, 0);
    end
    
    % Display results
    fprintf('%6.1f        %7.2f%10.2f%11.2f       %s\n',elapsedTime, currentTemp, rateCpm, predictedTemp, status);
    
    % Wait for next sample
    pause(SAMPLE_INTERVAL);
end

% Cleanup
% Turn off all LEDs
writeDigitalPin(arduinoObj, greenPin, 0);
writeDigitalPin(arduinoObj, yellowPin, 0);
writeDigitalPin(arduinoObj, redPin, 0);
end