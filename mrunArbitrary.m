function status = mrunArbitrary(device, y, a, offset, freq, dwell)
    % mrunArbitrary.m Does a measurement run for an arbitrary waveform.
    % Inputs:
    %   device : Reference to the picoscope device.
    %   y : Array of get(sigGenGroupObj, 'awgBufferSize') length with normalised Y values.
    %   a : Amplitude of the sine (mV)
    %   offset: DC offset of the sine (mV)
    %   freq: Single or a set interval range of frequencies to cycle. (Hz)
    %   dwell: How long to stay on single frequency (s)
    % Outputs:
    %   status: status of PicoScope
    PS5000aConfig;
    sigGenGroupObj = get(device, 'Signalgenerator');
    sigGenGroupObj = sigGenGroupObj(1);
    set(sigGenGroupObj, 'startFrequency', min(freq));
    set(sigGenGroupObj, 'stopFrequency', max(freq));
    set(sigGenGroupObj, 'offsetVoltage', offset);
    set(sigGenGroupObj, 'peakToPeakVoltage', a);
    [status.setSigGenArbitrarySimple] = invoke(sigGenGroupObj, 'setSigGenArbitrarySimple', y);

    increment = 0;
    if (numel(freq) > 1)
        increment = mean(diff(freq));
    end

    sweepType 			= ps5000aEnuminfo.enPS5000ASweepType.PS5000A_UP;
    operation 			= ps5000aEnuminfo.enPS5000AExtraOperations.PS5000A_ES_OFF;
    indexMode 			= ps5000aEnuminfo.enPS5000AIndexMode.PS5000A_SINGLE;
    shots 				= 0;
    sweeps 				= 0;
    triggerType 		= ps5000aEnuminfo.enPS5000ASigGenTrigType.PS5000A_SIGGEN_RISING;
    triggerSource 		= ps5000aEnuminfo.enPS5000ASigGenTrigSource.PS5000A_SIGGEN_SOFT_TRIG;
    extInThresholdMv 	= 0;
    
    % Dunno why but dwell/2 seems to work lol.
    [status.setSigGenArbitrary] = invoke(sigGenGroupObj, 'setSigGenArbitrary', increment, dwell/2, y, sweepType, ...
										    operation, indexMode, shots, sweeps, triggerType, triggerSource, extInThresholdMv);
    
    % Trigger the AWG
    [status.sigGenSoftwareControl] = invoke(sigGenGroupObj, 'ps5000aSigGenSoftwareControl', 1);

        pause(numel(freq) * dwell);

    %% Turn off signal generator
    [status.setSigGenOff] = invoke(sigGenGroupObj, 'setSigGenOff');

end