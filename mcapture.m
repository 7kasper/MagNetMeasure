function [time, chA, chB, status] = mcapture(scope, ti, ptp, freq, waveforms)
    % mcapture.m Runs a picoscope capture for wavforms * 1/freq.
    % Inputs:
    %   scope : Reference to the picoscope scope.
    %   ti : Time interval of measurement.
    %   ptp : Peak to peak of the waveform, used to set channel resolution.
    %   freq: Frequenty to run at (Hz)
    %   waveforms: Amount of full waveforms to capture.
    % Outputs:
    %   time: vector of measurepoints timeindex.
    %   chA: Output of channel A.
    %   chB: Output of channel B.
    %   status: status of PicoScope

    % Some setup
    PS5000aConfig;

    % Determine the input range for the picoscope to measure with max accuracy.
    if (ptp < 0.01)
        chanARange = ps5000aEnuminfo.enPS5000ARange.PS5000A_10MV;
    elseif (ptp < 0.02)
        chanARange = ps5000aEnuminfo.enPS5000ARange.PS5000A_20MV;
    elseif (ptp < 0.05)
        chanARange = ps5000aEnuminfo.enPS5000ARange.PS5000A_50MV;
    elseif (ptp < 0.1)
        chanARange = ps5000aEnuminfo.enPS5000ARange.PS5000A_100MV;
    elseif (ptp < 0.2)
        chanARange = ps5000aEnuminfo.enPS5000ARange.PS5000A_200MV;
    elseif (ptp < 0.5)
        chanARange = ps5000aEnuminfo.enPS5000ARange.PS5000A_500MV;
    elseif (ptp < 1)
        chanARange = ps5000aEnuminfo.enPS5000ARange.PS5000A_1V;
    elseif (ptp < 2)
        chanARange = ps5000aEnuminfo.enPS5000ARange.PS5000A_2V;
    elseif (ptp < 5)
        chanARange = ps5000aEnuminfo.enPS5000ARange.PS5000A_5V;
    elseif (ptp < 10)
        chanARange = ps5000aEnuminfo.enPS5000ARange.PS5000A_10V;
    elseif (ptp < 20)
        chanARange = ps5000aEnuminfo.enPS5000ARange.PS5000A_20V;
    else
        chanARange = ps5000aEnuminfo.enPS5000ARange.PS5000A_50V;
    end
    chanBRange = chanARange;

    % Set the channels (Namely turn on only channel A and B)
    [status.currentPowerSource] = invoke(scope, 'ps5000aCurrentPowerSource');
    [status.setChA] = invoke(scope, 'ps5000aSetChannel', 0, 1, 1, chanARange, 0.0);
    [status.setChB] = invoke(scope, 'ps5000aSetChannel', 1, 1, 1, chanBRange, 0.0);
    if (scope.channelCount == PicoConstants.QUAD_SCOPE && status.currentPowerSource == PicoStatus.PICO_POWER_SUPPLY_CONNECTED)
        [status.setChC] = invoke(scope, 'ps5000aSetChannel', 2, 0, 1, 8, 0.0);
        [status.setChD] = invoke(scope, 'ps5000aSetChannel', 3, 0, 1, 8, 0.0);
    end
    % Enable bandwidth filters on the channels.
    [status.bwfA] = invoke(scope, 'ps5000aSetBandwidthFilter', 0, ps5000aEnuminfo.enPS5000ABandwidthLimiter.PS5000A_BW_20MHZ);
    [status.bwfB] = invoke(scope, 'ps5000aSetBandwidthFilter', 1, ps5000aEnuminfo.enPS5000ABandwidthLimiter.PS5000A_BW_20MHZ);
    % Set resolution of the picoscope. (12 bit is enough)
    [status.setResolution, resolution] = invoke(scope, 'ps5000aSetDeviceResolution', 12);
    
    % Set memory segments
    % Configure the number of memory segments and query |ps5000aMemorySegments()|
    % to find the maximum number of samples for each segment.
    % nSegments : 64
    nSegments = 64;
    [status.memorySegments, nMaxSamples] = invoke(scope, 'ps5000aMemorySegments', nSegments);
    % Calculate amount of samples from there to capture specified waveforms.
    captureTime = waveforms * 1/freq;
    prepostSamples = min(int32(ceil((captureTime/(ti * 1e-9) / 2))), nMaxSamples);
    % Set number of samples to collect pre- and post-trigger. Ensure that the
    % total does not exceeed nMaxSamples above.
    set(scope, 'numPreTriggerSamples', prepostSamples);
    set(scope, 'numPostTriggerSamples', prepostSamples);

    %% Set simple trigger
    % Set a trigger on channel A, with an auto timeout - the default value for
    % delay is used. The scope will wait for a rising edge through
    % the specified threshold unless the timeout occurs first.
    % Trigger properties and functions are located in the Instrument
    % Driver's Trigger group.
    triggerGroupObj = get(scope, 'Trigger');
    triggerGroupObj = triggerGroupObj(1);
    % Set the |autoTriggerMs| property in order to automatically trigger the
    % oscilloscope after 1 second if a trigger event has not occurred. Set to 0
    % to wait indefinitely for a trigger event.
    set(triggerGroupObj, 'autoTriggerMs', 3000);

    source = ps5000aEnuminfo.enPS5000AChannel.PS5000A_EXTERNAL;
    % Channel     : 0 (ps5000aEnuminfo.enPS5000AChannel.PS5000A_CHANNEL_A)
    % Threshold   : 500 mV
    % Direction   : 2 (ps5000aEnuminfo.enPS5000AThresholdDirection.PS5000A_RISING)
    [status.setSimpleTrigger] = invoke(triggerGroupObj, 'setSimpleTrigger', source, 5000, 2);
    %% Set rapid block parameters and capture data
    % Capture a number of waveof and retrieve data values for channels A and B.
    % Rapid Block specific properties and functions are located in the
    % Instrument Driver's Rapidblock group.
    rapidBlockGroupObj = get(scope, 'Rapidblock');
    rapidBlockGroupObj = rapidBlockGroupObj(1);
    % Block specific properties and functions are located in the Instrument
    % Driver's Block group.
    blockGroupObj = get(scope, 'Block');
    blockGroupObj = blockGroupObj(1);
    % Set number of captures - can be less than or equal to the number of
    % segments.
    numCaptures = 1;
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