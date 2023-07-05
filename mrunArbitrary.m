function [time, chA, chB, status] = mrunArbitrary(scope, fgen, ti, y, ptp, offset, freq, waveforms, dwell)
    % mrunArbitrary.m Does a measurement run for an arbitrary waveform.
    % Inputs:
    %   scope : Reference to the picoscope scope.
    %   fgen : Reference to the T3AFG120 waveform generator.
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

    % Here comes the magic.
    % First we normalise the raw data points. This way the peak to peak makes sense.
    % We also multiply with 2^15-1 as this is the maximum value in a 2-s complement (signed) 16 bit integer.
    % We round and transform to int16 for the correct data.
    yint16 = int16(round(normalise(y) * ((2^15)-1)));
    % We then transform the 16 bit numbers in tuplets of raw binary bytes.
    yuint8 = char(typecast(yint16,'uint8'));
    % Phase offset TODO implement?
    ph = 0.0;
    % We can push this to the scope:
    fwrite(fgen, sprintf('C1:WVDT WVNM,wave2,FREQ,%f,AMPL,%f,OFST,%f,PHASE,%f,WAVEDATA,%s', freq, ptp, offset, ph, yuint8));
    fwrite(fgen,'C1:ARWV NAME,wave2');
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