function [time, chA, chB, status] = mrunSimple(devs, type, ptp, offset, freq, waveforms, dwell)
    % mrunSimple.m Does a measurement run for a simple waveform.
    % Inputs:
    %   devs : Reference to devices and calibration properties.
    %   type : type of waveform (SINE, SQUARE, RAMP, PULSE, NOISE, DC, PRBS, IQ)
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

    % Compensate amplifier gain:
    if devs.calAmp ~= 0
        fgenPtp = ptp / devs.calAmp;
        offset = offset / devs.calAmp;
    else
        fgenPtp = ptp;
    end
    % Compensate amplifier offset:
    if devs.calOffset ~= 0
        offset = offset - devs.calOffset;
    end

    % Phase offset TODO implement?
    ph = 0.0;
    % We can push this to the scope:
    fwrite(devs.fgen, sprintf('C1:BSWV   WVTP,%s,FRQ,%f,AMP,%f,OFST,%f,PHSE,%f', type, freq, fgenPtp*2, offset, ph));
    fwrite(devs.fgen,'C1:OUTP ON,LOAD,50');
    % Wait until fgen is ready.
    fwrite(devs.fgen,'*OPC?');
    fscanf(devs.fgen);

    % Dwell in start to settle the behaviour.
    pause(dwell(1));

    % Measure
    [time, status, chA, chB] = mcapture(devs.scope, devs.ti, [0, 1], ptp, freq, waveforms);

    % Dwell in end to settle the behaviour.
    pause(dwell(end));
    
    %% Turn off signal generator
    fwrite(devs.fgen,'C1:OUTP OFF');
end

