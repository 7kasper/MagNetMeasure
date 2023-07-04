function [time, chA, chB, status] = mcapact(device, ti, freq, waveforms)
    % mcapture.m Runs a picoscope capture for wavforms * 1/freq.
    % Inputs:
    %   device : Reference to the picoscope device.
    %   ti : Time interval of measurement.
    %   freq: Frequenty to run at (Hz)
    %   waveforms: Amount of full waveforms to capture.
    % Outputs:
    %   time: vector of measurepoints timeindex.
    %   chA: Output of channel A.
    %   chB: Output of channel B.
    %   status: status of PicoScope

    % Some setup
    PS5000aConfig;
    rapidBlockGroupObj = get(device, 'Rapidblock');
    rapidBlockGroupObj = rapidBlockGroupObj(1);
    % Block specific properties and functions are located in the Instrument
    % Driver's Block group.
    blockGroupObj = get(device, 'Block');
    blockGroupObj = blockGroupObj(1);
    %% Measuring
    % Start measuring
    [status.runBlock, timeIndisposedMs] = invoke(blockGroupObj, 'runBlock', 0);
    % Retrieve rapid block data values:
    downsamplingRatio       = 1;
    downsamplingRatioMode   = ps5000aEnuminfo.enPS5000ARatioMode.PS5000A_RATIO_MODE_NONE;
    % Provide additional output arguments for the remaining channels e.g. chC
    % for Channel C
    numCaptures = 1;
    [numSamples, overflow, chA, chB] = invoke(rapidBlockGroupObj, 'getRapidBlockData', numCaptures, ...
                                       downsamplingRatio, downsamplingRatioMode);
    % Number of captures
    [status.getNoOfCaptures, numCaptures] = invoke(rapidBlockGroupObj, 'ps5000aGetNoOfCaptures');
    % Calculate the time
    timeNs = double(ti) * downsamplingRatio * double(0:numSamples - 1);
    time = timeNs / 10e9;
    % time = [];
    % chA = [];
    % chB = [];
    
end