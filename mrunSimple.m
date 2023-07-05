function [time, chA, chB, status] = mrunSimple(scope, fgen, ti, type, ptp, offset, freq, waveforms, dwell)
    % mrunSimple.m Does a measurement run for a simple waveform.
    % Inputs:
    %   scope : Reference to the picoscope scope.
    %   fgen : Reference to the T3AFG120 waveform generator.
    %   ti : Time interval of measurement.
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

    % Phase offset TODO implement?
    ph = 0.0;
    % We can push this to the scope:
    fwrite(fgen, sprintf('C1:BSWV   WVTP,%s,FRQ,%f,AMP,%f,OFST,%f,PHSE,%f', type, freq, ptp, offset, ph));
    fwrite(fgen,'C1:OUTP ON');
    fwrite(fgen,'*OPC?');
    fscanf(fgen);

    % Dwell in start to settle the behaviour.
    pause(dwell(1));

    % Measure
    [time, chA, chB, status] = mcapture(scope, ti, ptp, freq, waveforms);

    % Dwell in end to settle the behaviour.
    pause(dwell(end));
    
    %% Turn off signal generator
    fwrite(fgen,'C1:OUTP OFF');
end

