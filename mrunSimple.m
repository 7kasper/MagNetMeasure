function status = mrunSimple(device, timeIntervalNanoseconds, type, a, offset, freq, dwell, waveforms)
    % mrunSimple.m Does a measurement run for a simple waveform.
    % Inputs:
    %   device : Reference to the picoscope device.
    %   type : type of waveform (ps5000aEnuminfo.enPS5000AWaveType.PS5000A_SQUARE)
    %   a : Amplitude of the sine (mV)
    %   offset: DC offset of the sine (mV)
    %   freq: Single or a set interval range of frequencies to cycle. (Hz)
    %   dwell: Dwell is the settle time before and after measuring.
    %   waveforms: Amount of full waveforms to capture.
    % Outputs:
    %   status: status of PicoScope
    PS5000aConfig;
    sigGenGroupObj = get(device, 'Signalgenerator');
    sigGenGroupObj = sigGenGroupObj(1);
    [status.setSigGenBuiltInSimple] = invoke(sigGenGroupObj, 'setSigGenBuiltInSimple', 0);
    % Configure property value(s).    
    set(sigGenGroupObj, 'startFrequency', min(freq));
    set(sigGenGroupObj, 'stopFrequency', max(freq));
    set(sigGenGroupObj, 'offsetVoltage', offset);
    set(sigGenGroupObj, 'peakToPeakVoltage', a);

    increment = 0;
    if (numel(freq) > 1)
        increment = mean(diff(freq));
    end
    
    sweepType 			= ps5000aEnuminfo.enPS5000ASweepType.PS5000A_UP;
    operation 			= ps5000aEnuminfo.enPS5000AExtraOperations.PS5000A_ES_OFF;
    shots 				= 0;
    sweeps 				= 0;
    triggerType 		= ps5000aEnuminfo.enPS5000ASigGenTrigType.PS5000A_SIGGEN_RISING;
    triggerSource 		= ps5000aEnuminfo.enPS5000ASigGenTrigSource.PS5000A_SIGGEN_NONE;
    extInThresholdMv 	= 0;
    
    % Execute device object function(s).
    [status.setSigGenBuiltIn] = invoke(sigGenGroupObj, 'setSigGenBuiltIn', type, increment, dwell, ...
        sweepType, operation, shots, sweeps, triggerType, triggerSource, extInThresholdMv);

    %% Set memory segments
    % Configure the number of memory segments and query |ps5000aMemorySegments()|
    % to find the maximum number of samples for each segment.
    % nSegments : 64
    nSegments = 64;
    [status.memorySegments, nMaxSamples] = invoke(ps5000aDeviceObj, 'ps5000aMemorySegments', nSegments);
    % Set number of samples to collect pre- and post-trigger. Ensure that the
    % total does not exceeed nMaxSamples above.
    set(ps5000aDeviceObj, 'numPreTriggerSamples', 262144);
    set(ps5000aDeviceObj, 'numPostTriggerSamples', 262144);
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
    %% 
    % This example uses the |runBlock()| function in order to collect a block of
    % data - if other code needs to be executed while waiting for the device to
    % indicate that it is ready, use the |ps5000aRunBlock()| function and poll
    % the |ps5000aIsReady()| function until the device indicates that it has
    % data available for retrieval.
    % Capture the blocks of data:
    % segmentIndex : 0 
    [status.runBlock, timeIndisposedMs] = invoke(blockGroupObj, 'runBlock', 0);
    % Retrieve rapid block data values:
    downsamplingRatio       = 1;
    downsamplingRatioMode   = ps5000aEnuminfo.enPS5000ARatioMode.PS5000A_RATIO_MODE_NONE;
    % Provide additional output arguments for the remaining channels e.g. chC
    % for Channel C
    numCaptures = 8;
    [numSamples, overflow, chA, chB] = invoke(rapidBlockGroupObj, 'getRapidBlockData', numCaptures, ...
                                        downsamplingRatio, downsamplingRatioMode);
    %% Obtain the number of captures
    [status.getNoOfCaptures, numCaptures] = invoke(rapidBlockGroupObj, 'ps5000aGetNoOfCaptures');
    %% Process data
    % Plot data values.
    %
    % Calculate the time period over which samples were taken for each waveform.
    % Use the |timeIntNs| output from the |ps5000aGetTimebase2()| function or
    % calculate the sampling interval using the main Programmer's Guide.
    % Take into account the downsampling ratio used.
    timeNs = double(timeIntervalNanoseconds) * downsamplingRatio * double(0:numSamples - 1);

    % Channel A
    figure1 = figure('Name','PicoScope 5000 Series (A API) Example - Rapid Block Mode Capture', ...
        'NumberTitle', 'off');
    plot(timeNs, chA);
    title('Channel A');
    xlabel('Time (ns)');
    ylabel('Voltage (mV)');
    grid on;
    movegui(figure1, 'west');
    % Channel B
    figure2  = figure('Name','PicoScope 5000 Series (A API) Example - Rapid Block Mode Capture', ...
        'NumberTitle', 'off');
    plot(timeNs, chB);
    title('Channel B - Rapid Block Capture');
    xlabel('Time (ns)');
    ylabel('Voltage (mV)')
    grid on;
    movegui(figure2, 'east');

    % TODO: Actually measure during this time.
    % pause(numel(freq) * dwell);

    [status.setSigGenOff] = invoke(sigGenGroupObj, 'setSigGenOff');
end

