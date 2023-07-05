function [amp, offset, status] = mrunCal(devs, type, ptp, freq, dwell)
    % mrunCal.m Does a calibration run with a simple waveform.
    % Inputs:
    %   devs : Reference to devices and calibration properties.
    %   type : type of waveform (SINE, SQUARE, RAMP, PULSE, NOISE, DC, PRBS, IQ)
    %   ptp : Peak to peak of the waveform (V)
    %   freq: Frequenty to run at (Hz)
    %   dwell: Dwell is the settle time before and after measuring.
    % Outputs:
    %    amp : amplitude difference caused by amplifier.
    %   offset : Offset of measured wave with input.

    % We can push this to the scope:
    fwrite(devs.fgen, sprintf('C1:BSWV   WVTP,%s,FRQ,%f,AMP,%f,OFST,0.0', type, freq, ptp*2));
    fwrite(devs.fgen,'C1:OUTP ON,LOAD,50');
    % Wait until fgen is ready.
    fwrite(devs.fgen,'*OPC?');
    fscanf(devs.fgen);

    % Dwell in start to settle the behaviour.
    pause(dwell(1));

    % Measure 6 waveforms. We guess the ptp is 10x as big to be able to measure it. (It is less but we will find out) 
    [time, status, ~, ~, chC] = mcapture(devs.scope, devs.ti, [2], ptp*10, freq, 6);
    plot(time, chC);
    amp = peak2peak(chC)/ptp;
    offset = mean(chC)/amp;

    % Dwell in end to settle the behaviour.
    pause(dwell(end));
    
    %% Turn off signal generator
    fwrite(devs.fgen,'C1:OUTP OFF');
end

