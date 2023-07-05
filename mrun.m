function [] = mrun(scope, fgen, ti)
    
    awgBufferSize = fgen.OutputBufferSize/3;
    x = 0:(2*pi)/(awgBufferSize - 1):2*pi;
    y = normalise(sin(x) + sin(2*x) + sin(3*x));

    [time, chA, chB] = mrunSimple(scope, fgen, ti, 'RAMP', 0.06, 0, 1000, 2, 2);
    % (60/5.066)
    % [time, chA, chB] = mrunArbitrary(scope, fgen, ti, y, 1, 0.1, 1000, 6, 1);


    chA = mean(chA, 2);

    % Channel A
    figure1 = figure('Name','PicoScope 5000 Series (A API) Example - Rapid Block Mode Capture', ...
        'NumberTitle', 'off');
    plot(time, chA);
    title('Channel A');
    xlabel('Time (s)');
    ylabel('Voltage (V)');
    grid on;
    movegui(figure1, 'west');
    % Channel B
    figure2  = figure('Name','PicoScope 5000 Series (A API) Example - Rapid Block Mode Capture', ...
        'NumberTitle', 'off');
    plot(time, chB);
    title('Channel B - Rapid Block Capture');
    xlabel('Time (s)');
    ylabel('Voltage (mV)')
    grid on;
    movegui(figure2, 'east');

end

