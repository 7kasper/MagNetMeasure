function [time, chA, chB, status] = mcapture(device, ti, freq, waveforms)
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
    
    % Set memory segments
    % Configure the number of memory segments and query |ps5000aMemorySegments()|
    % to find the maximum number of samples for each segment.
    % nSegments : 64
    nSegments = 64;
    [status.memorySegments, nMaxSamples] = invoke(device, 'ps5000aMemorySegments', nSegments);
    % Calculate amount of samples from there to capture specified waveforms.
    captureTime = waveforms * 1/freq;
    prepostSamples = min(int32(ceil((captureTime/(ti * 1e-9) / 2))), nMaxSamples);
    % Set number of samples to collect pre- and post-trigger. Ensure that the
    % total does not exceeed nMaxSamples above.
    set(device, 'numPreTriggerSamples', prepostSamples);
    set(device, 'numPostTriggerSamples', prepostSamples);

    %% Set simple trigger
    % Set a trigger on channel A, with an auto timeout - the default value for
    % delay is used. The device will wait for a rising edge through
    % the specified threshold unless the timeout occurs first.
    % Trigger properties and functions are located in the Instrument
    % Driver's Trigger group.
    triggerGroupObj = get(device, 'Trigger');
    triggerGroupObj = triggerGroupObj(1);
    % Set the |autoTriggerMs| property in order to automatically trigger the
    % oscilloscope after 1 second if a trigger event has not occurred. Set to 0
    % to wait indefinitely for a trigger event.
    set(triggerGroupObj, 'autoTriggerMs', 1000);
    % Channel     : 0 (ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_A)
    % Threshold   : 500 mV
    % Direction   : 2 (ps5000aEnuminfo.enPS5000AThresholdDirection.PS5000A_RISING)
    [status.setSimpleTrigger] = invoke(triggerGroupObj, 'setSimpleTrigger', 0, 500, 2);
    %% Set rapid block parameters and capture data
    % Capture a number of waveof and retrieve data values for channels A and B.
    % Rapid Block specific properties and functions are located in the
    % Instrument Driver's Rapidblock group.
    rapidBlockGroupObj = get(device, 'Rapidblock');
    rapidBlockGroupObj = rapidBlockGroupObj(1);
    % Block specific properties and functions are located in the Instrument
    % Driver's Block group.
    blockGroupObj = get(device, 'Block');
    blockGroupObj = blockGroupObj(1);
    % Set number of captures - can be less than or equal to the number of
    % segments.
    numCaptures = 8;
    [status.setNoOfCaptures] = invoke(rapidBlockGroupObj, 'ps5000aSetNoOfCaptures', numCaptures);
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
    
end