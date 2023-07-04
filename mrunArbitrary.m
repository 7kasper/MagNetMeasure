function [time, chA, chB, status] = mrunArbitrary(device, ti, y, ptp, offset, freq, waveforms,dwell)
    % mrunArbitrary.m Does a measurement run for an arbitrary waveform.
    % Inputs:
    %   device : Reference to the picoscope device.
    %   ti : Time interval of measurement.
    %   y : Array of get(sigGenGroupObj, 'awgBufferSize') length with normalised Y values.
    %   ptp : Peak to peak of the waveform (V)
    %   offset: DC offset of the sine (V)
    %   freq: Single or a set interval range of frequencies to cycle. (Hz)
    %   waveforms: Amount of full waveforms to capture.
    %   dwell: How long to stay on single frequency (s)
    % Outputs:
    %   time: vector of measurepoints timeindex.
    %   chA: Output of channel A.
    %   chB: Output of channel B.
    %   status: status of PicoScope

    % Some setup
    PS5000aConfig;
    sigGenGroupObj = get(device, 'Signalgenerator');
    sigGenGroupObj = sigGenGroupObj(1);

    % Configure property value(s).    
    set(sigGenGroupObj, 'startFrequency', min(freq));
    set(sigGenGroupObj, 'stopFrequency', max(freq));
    set(sigGenGroupObj, 'offsetVoltage', offset*1000);
    set(sigGenGroupObj, 'peakToPeakVoltage', ptp*1000);
    [status.setSigGenArbitrarySimple] = invoke(sigGenGroupObj, 'setSigGenArbitrarySimple', y);

    % When multiple frequencies are given (not supported for capturing yet)
    increment = 0;
    if (numel(freq) > 1)
        increment = mean(diff(freq));
    end

    mcapture(device, ti, freq, waveforms);


    % Setup signal generator properties.
    sweepType 			= ps5000aEnuminfo.enPS5000ASweepType.PS5000A_UP;
    operation 			= ps5000aEnuminfo.enPS5000AExtraOperations.PS5000A_ES_OFF;
    indexMode 			= ps5000aEnuminfo.enPS5000AIndexMode.PS5000A_SINGLE;
    shots 				= 10;
    sweeps 				= 0;
    triggerType 		= ps5000aEnuminfo.enPS5000ASigGenTrigType.PS5000A_SIGGEN_RISING;
    triggerSource 		= ps5000aEnuminfo.enPS5000ASigGenTrigSource.PS5000A_SIGGEN_SCOPE_TRIG;
    extInThresholdMv 	= 0;
    
    % Turn on the signal generator.
    % Dunno why but dwell/2 seems to work lol.
    [status.setSigGenArbitrary] = invoke(sigGenGroupObj, 'setSigGenArbitrary', increment, (dwell/2)*1.1, y, sweepType, ...
										    operation, indexMode, shots, sweeps, triggerType, triggerSource, extInThresholdMv);
    
    % Trigger the AWG
    
    % Dwell in start to settle the behaviour.
    % pause(dwell(1));
    
    % Record the required data.

    time = [];
    chA = [];
    chB = [];

    [time, chA, chB] = mcapact(device, ti, freq, waveforms);

    % [status.sigGenSoftwareControl] = invoke(sigGenGroupObj, 'ps5000aSigGenSoftwareControl', 1);

    % Dwell in end to settle the behaviour.
    %pause(dwell(end));

    %% Turn off signal generator
    [status.setSigGenOff] = invoke(sigGenGroupObj, 'setSigGenOff');

end