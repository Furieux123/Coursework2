% Bofan ZOU
% ssybz7@nottingham.edu.cn


%% PRELIMINARY TASK
clear all
a = arduino;

for i=1:10
    writeDigitalPin(a,'D2',1)
    pause(0.5)
    writeDigitalPin(a,'D2',0)
    pause(0.5)
end


%% TASK 1

% a) Hardware setup
% Connect MCP9700A temperature sensor:
% - Pin 1 (VCC) -> 5V
% - Pin 2 (VOUT) -> Analog pin A0
% - Pin 3 (GND) -> GND
% See figure in word document

% b) Data acquisition parameters
duration = 600; % 10 minutes in seconds
sampleInterval = 1; % Sample every 1 second
numSamples = duration / sampleInterval;

% Preallocate arrays for efficiency
timeData = zeros(1, numSamples);
voltageData = zeros(1, numSamples);
tempData = zeros(1, numSamples);

% MCP9700A sensor constants (from datasheet)
TC = 0.01; % Temperature coefficient: 10mV/°C = 0.01 V/°C
V0C = 0.5; % Output voltage at 0°C: 500mV = 0.5V

% Data acquisition loop
for i = 1:numSamples
    % Read voltage from analog pin A0
    voltage = readVoltage(a, 'A0');
    voltageData(i) = voltage;
    
    % Convert voltage to temperature
    temperature = (voltage - V0C) / TC;
    tempData(i) = temperature;
    
    % Record time
    timeData(i) = (i-1) * sampleInterval;
    
    % Wait for next sample
    pause(sampleInterval);
    
    % Display progress every minute
    if mod(i, 60) == 0
        fprintf('Progress: %d minutes completed\n', i/60);
    end
end

% Calculate statistics
minTemp = min(tempData);
maxTemp = max(tempData);
avgTemp = mean(tempData);

% c) Create temperature/time plot
figure('Name', 'Temperature vs Time');
plot(timeData/60, tempData, 'b-', 'LineWidth', 1.5);
xlabel('Time (minutes)');
ylabel('Temperature (°C)');
title('Capsule Temperature Monitoring Over 10 Minutes');
grid on;
saveas(gcf, 'temperature_plot.png');

% d) Print formatted output to screen using sprintf
currentDate = datetime('now', 'Format', 'MM/dd/yyyy');
fprintf('Data logging initiated - %s\n', char(currentDate));
fprintf('Location - Nottingham\n\n');

% Print temperature data every minute (every 60 samples)
for minute = 0:10
    idx = minute * 60 + 1;
    if idx <= length(tempData)
        fprintf('Minute\t%d\t\tTemperature\t%5.2f °C\n', minute, tempData(idx));
    end
end

% Print statistics
fprintf('\nMax temp\t\t%5.2f °C\n', maxTemp);
fprintf('Min temp\t\t%5.2f °C\n', minTemp);
fprintf('Average temp\t\t%5.2f °C\n', avgTemp);
fprintf('\nData logging terminated\n');

% e) Write data to log file
fileID = fopen('capsule_temperature.txt', 'w');
fprintf(fileID, 'Data logging initiated - %s\n', currentDate);
fprintf(fileID, 'Location - Nottingham\n\n');

% Write temperature data every minute
for minute = 0:10
    idx = minute * 60 + 1;
    if idx <= length(tempData)
        fprintf(fileID, 'Minute\t%d\t\tTemperature\t%5.2f °C\n', minute, tempData(idx));
    end
end

% Write statistics
fprintf(fileID, '\nMax temp\t\t%5.2f °C\n', maxTemp);
fprintf(fileID, 'Min temp\t\t%5.2f °C\n', minTemp);
fprintf(fileID, 'Average temp\t\t%5.2f °C\n', avgTemp);
fprintf(fileID, '\nData logging terminated\n');

fclose(fileID);
disp('Data written to capsule_temperature.txt');

% Verify file by reading it back
verifyID = fopen('capsule_temperature.txt', 'r');
if verifyID ~= -1
    fileContent = fread(verifyID, '*char')';
    fclose(verifyID);
    disp('File verification: File read successfully');
end

%% TASK 2

% f) Hardware setup for Task 2
% Connect three LEDs:
% - Green LED: long leg to D2, short leg to 220Ω resistor to GND
% - Yellow LED: long leg to D3, short leg to 220Ω resistor to GND  
% - Red LED: long leg to D4, short leg to 220Ω resistor to GND
% Photograph is included in Word document

% g) Flowchart (included in Word document)

% h) See the temperature monitoring function

% i) Graph (included in Word document)

% j,k) See the temperature monitoring function
temp_monitor(a, 60)

% l) Explanation of the function
doc temp_monitor


%% TASK 3

% a) Flowchart (included in Word document)

% b,c,d) Call temperature prediction function
temp_prediction(a, 60);

% e) Explanation of the function
doc temp_prediction

% Cleanup
% Turn off all LEDs
writeDigitalPin(a, greenPin, 0);
writeDigitalPin(a, yellowPin, 0);
writeDigitalPin(a, redPin, 0);
% Clear Arduino object
clear a;