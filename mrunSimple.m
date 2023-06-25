function [time, chA, chB, status] = mrunSimple(device, ti, type, ptp, offset, freq, waveforms, dwell)
    % mrunSimple.m Does a measurement run for a simple waveform.
    % Inputs:
    %   device : Reference to the picoscope device.
    %   ti : Time interval of measurement.
    %   type : type of waveform (ps5000aEnuminfo.enPS5000AWaveType.PS5000A_SQUARE)
    %   ptp : Peak to peak of the waveform (V)
    %   offset: DC offset of the sine (V)
    %   freq: Frequenty to run at (Hz)
    %   waveforms: Amount of full waveforms to capture.
    %   dwell: Dwell is the settle time before and after measuring.
    % Outputs:
    %   time: vector of measurepoints timeindex.
    %   chA: Output of channel A.
    %   chB: Output of channel B.
    %   status: status of PicoScope

    % Some setup
    PS5000aConfig;
    sigGenGroupObj = get(device, 'Signalgenerator');
    sigGenGroupObj = sigGenGroupObj(1);
    [status.setSigGenBuiltInSimple] = invoke(sigGenGroupObj, 'setSigGenBuiltInSimple', 0);

    % Configure property value(s).    
    set(sigGenGroupObj, 'startFrequency', min(freq));
    set(sigGenGroupObj, 'stopFrequency', max(freq));
    set(sigGenGroupObj, 'offsetVoltage', offset*1000);
    set(sigGenGroupObj, 'peakToPeakVoltage', ptp*1000);

    % When multiple frequencies are given (not supported for capturing yet)
    increment = 0;
    if (numel(freq) > 1)
        increment = mean(diff(freq));
    end

    % Setup signal generator properties.
    sweepType 			= ps5000aEnuminfo.enPS5000ASweepType.PS5000A_UP;
    operation 			= ps5000aEnuminfo.enPS5000AExtraOperations.PS5000A_ES_OFF;
    shots 				= 0;
    sweeps 				= 0;
    triggerType 		= ps5000aEnuminfo.enPS5000ASigGenTrigType.PS5000A_SIGGEN_RISING;
    triggerSource 		= ps5000aEnuminfo.enPS5000ASigGenTrigSource.PS5000A_SIGGEN_NONE;
    extInThresholdMv 	= 0;
    
    % Turn on the signal generator.
    [status.setSigGenBuiltIn] = invoke(sigGenGroupObj, 'setSigGenBuiltIn', type, increment, dwell*1.1, ...
        sweepType, operation, shots, sweeps, triggerType, triggerSource, extInThresholdMv);

    % Dwell in start to settle the behaviour.
    pause(dwell(1));
    
    % Record the required data.
    [time, chA, chB] = mcapture(device, ti, freq, waveforms);

    % Dwell in end to settle the behaviour.
    pause(dwell(end));

    [status.setSigGenOff] = invoke(sigGenGroupObj, 'setSigGenOff');
end

