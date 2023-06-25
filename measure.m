%% === Kasper Müller PES-Project ===
% Script for the MagNet challenge.
% Responsible for driving picoscope measurement

%% Instal instructions
% Before running make sure you istall
% Instrument Control Toolbox (matlab extension)
% Picoscope Support Toolbox (matlab package)
% Picscope 5000 series instrument driver (matlab package)
% PicoSDK (https://www.picotech.com/downloads)
% PicoSDK C wrappers (https://github.com/picotech/picosdk-c-wrappers-binaries/tree/master)
% Drop the (windows) C wrappers into the PicoSDK lib folder.
% Add the lib folder to matlab path using addpath('C:\Program Files\Pico Technology\SDK\lib');

% Functionality is deined in mrub.m!

%% Pre-Setup
clc;
close all;

%% Load configuration information
PS5000aConfig;

%% Device connection

% Check if an Instrument session using the device object |ps5000aDeviceObj|
% is still open, and if so, disconnect if the User chooses 'Yes' when prompted.
if (exist('ps5000aDeviceObj', 'var') && ps5000aDeviceObj.isvalid && strcmp(ps5000aDeviceObj.status, 'open'))
    openDevice = questionDialog(['Device object ps5000aDeviceObj has an open connection. ' ...
        'Do you wish to close the connection and continue?'], ...
        'Device Object Connection Open');
    if (openDevice == PicoConstants.TRUE)
        % Close connection to device.
        disconnect(ps5000aDeviceObj);
        delete(ps5000aDeviceObj);
    else
        return;
    end
end

%% Opject creation

% Create a device object. 
ps5000aDeviceObj = icdevice('picotech_ps5000a_generic.mdd');
connect(ps5000aDeviceObj);

% Set the channels (Namely turn on only A & B)
[status.currentPowerSource] = invoke(ps5000aDeviceObj, 'ps5000aCurrentPowerSource');
if (ps5000aDeviceObj.channelCount == PicoConstants.QUAD_SCOPE && status.currentPowerSource == PicoStatus.PICO_POWER_SUPPLY_CONNECTED)
    [status.setChC] = invoke(ps5000aDeviceObj, 'ps5000aSetChannel', 2, 0, 1, 8, 0.0);
    [status.setChD] = invoke(ps5000aDeviceObj, 'ps5000aSetChannel', 3, 0, 1, 8, 0.0);
end
% Enable bandwidth filters on the channels.
[status.bwfA] = invoke(ps5000aDeviceObj, 'ps5000aSetBandwidthFilter', 0, ps5000aEnuminfo.enPS5000ABandwidthLimiter.PS5000A_BW_20MHZ);
[status.bwfB] = invoke(ps5000aDeviceObj, 'ps5000aSetBandwidthFilter', 1, ps5000aEnuminfo.enPS5000ABandwidthLimiter.PS5000A_BW_20MHZ);

% Set resolution of the picoscope. (12 bit is enough)
[status.setResolution, resolution] = invoke(ps5000aDeviceObj, 'ps5000aSetDeviceResolution', 12);

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
    [status.getTimebase2, timeIntervalNanoseconds, maxSamples] = invoke(ps5000aDeviceObj, 'ps5000aGetTimebase2', timebaseIndex, 0);
    if (status.getTimebase2 == PicoStatus.PICO_OK)
        break;
    else
        timebaseIndex = timebaseIndex + 1;
    end    
end
fprintf('Timebase index: %d, sampling interval: %d ns\n', timebaseIndex, timeIntervalNanoseconds);
% Configure the device object's |timebase| property value.
set(ps5000aDeviceObj, 'timebase', timebaseIndex);

%% Program
mrun(ps5000aDeviceObj, timeIntervalNanoseconds);

%% Wrap up
[status.stop] = invoke(ps5000aDeviceObj, 'ps5000aStop');
disconnect(ps5000aDeviceObj);
delete(ps5000aDeviceObj);