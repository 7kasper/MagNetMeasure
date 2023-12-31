%% === Kasper Müller PES-Project ===
% Script for the MagNet challenge.
% Responsible for driving T3AFG & picoscope measurement

%% Instal instructions
% Before running make sure you istall
% Instrument Control Toolbox (matlab extension)
% Picoscope Support Toolbox (matlab package)
% Picscope 5000 series instrument driver (matlab package)
% NI-Visa (https://www.ni.com/en-us/support/downloads/drivers/download.ni-visa.html)
% PicoSDK (https://www.picotech.com/downloads)
% PicoSDK C wrappers (https://github.com/picotech/picosdk-c-wrappers-binaries/tree/master)
% Drop the (windows) C wrappers into the PicoSDK lib folder.
% Add the lib folder to matlab path using addpath('C:\Program Files\Pico Technology\SDK\lib');

% Functionality is defined in mrun.m!

%% Pre-Setup
clc;
close all;

%% Load configuration information
PS5000aConfig;

%% Device connections

% Check if an Instrument session using the device object |scope|
% is still open, and if so, disconnect if the User chooses 'Yes' when prompted.
if (exist('scope', 'var') && scope.isvalid && strcmp(scope.status, 'open'))
    % Close connection to device.
    disconnect(scope);
    delete(scope);
end

%% Opject creation

% Create a device objects. 
scope = icdevice('picotech_ps5000a_generic.mdd');
connect(scope);

fgen = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::0xF4ED::0xEE3A::T0102C22020014::0::INSTR', 'Tag', '');
% Create the VISA-USB object if it does not exist
% otherwise use the object that was found.
if isempty(fgen)
    fgen = visa('KEYSIGHT', 'USB0::0xF4ED::0xEE3A::T0102C22020014::0::INSTR');
else
    fclose(fgen);
    fgen = fgen(1);
end

% JUST VERY BIGGG
awgBufferSize = 8e6;
fgen.OutputBufferSize = awgBufferSize*3;

devs = Devices();
devs.bufferSize = awgBufferSize;

% Connect to instrument object, fgen.
fopen(fgen);

% % Set the channels (Namely turn off everything available)
% [status.currentPowerSource] = invoke(scope, 'ps5000aCurrentPowerSource');
% [status.setChA] = invoke(scope, 'ps5000aSetChannel', 0, 1, 1, 8, 0.0);
% [status.setChB] = invoke(scope, 'ps5000aSetChannel', 1, 0, 1, 8, 0.0);
% if (scope.channelCount == PicoConstants.QUAD_SCOPE && status.currentPowerSource == PicoStatus.PICO_POWER_SUPPLY_CONNECTED)
%     [status.setChC] = invoke(scope, 'ps5000aSetChannel', 2, 0, 1, 8, 0.0);
%     [status.setChD] = invoke(scope, 'ps5000aSetChannel', 3, 0, 1, 8, 0.0);
% end
% % Enable bandwidth filters on the channels.
% [status.bwfA] = invoke(scope, 'ps5000aSetBandwidthFilter', 0, ps5000aEnuminfo.enPS5000ABandwidthLimiter.PS5000A_BW_20MHZ);
% [status.bwfB] = invoke(scope, 'ps5000aSetBandwidthFilter', 1, ps5000aEnuminfo.enPS5000ABandwidthLimiter.PS5000A_BW_20MHZ);

% % Set resolution of the picoscope. (12 bit is enough)
% [status.setResolution, resolution] = invoke(scope, 'ps5000aSetDeviceResolution', 12);

%% Verify timebase index and maximum number of samples
% Use the |ps5000aGetTimebase2()| function to query the driver as to the
% suitability of using a particular timebase index and the maximum number
% of samples available in the segment selected, then set the |timebase|
% property if required.
%
% To use the fastest sampling interval possible, enable one analog
% channel and turn off all other channels.
%
% Use a while loop to query the function until the status indicates that a
% valid timebase index has been selected. In this example, the timebase
% index of 65 is valid.
% Initial call to ps5000aGetTimebase2() with parameters:
%
% timebase      : 4
% segment index : 0
status.getTimebase2 = PicoStatus.PICO_INVALID_TIMEBASE;
timebaseIndex = 3;
while (status.getTimebase2 == PicoStatus.PICO_INVALID_TIMEBASE)
    [status.getTimebase2, timeIntervalNanoseconds, maxSamples] = invoke(scope, 'ps5000aGetTimebase2', timebaseIndex, 0);
    if (status.getTimebase2 == PicoStatus.PICO_OK)
        break;
    else
        timebaseIndex = timebaseIndex + 1;
    end    
end
fprintf('Timebase index: %d, sampling interval: %d ns\n', timebaseIndex, timeIntervalNanoseconds);
% Configure the device object's |timebase| property value.
set(scope, 'timebase', timebaseIndex);

% Reset the function generator.
fprintf(fgen,'*RST');
fprintf(fgen,'C1:OUTP OFF');
% Turn on the sync channel
fprintf(fgen,"C1:SYNC ON,TYPE,MOD_CH1");

% Small setup settle delay
pause(1);

devs.scope = scope;
devs.fgen = fgen;
devs.ti = timeIntervalNanoseconds;

%% Run Program
mrun(devs);

%% Wrap up
[status.stop] = invoke(scope, 'ps5000aStop');
disconnect(scope);
delete(scope);
% fclose(fgen);
% delete(fgen);
% clear fgen;