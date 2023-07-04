function [] = mrun(device, ti)
    
    % Local setup:
    PS5000aConfig;
    sigGenGroupObj = get(device, 'Signalgenerator');
    sigGenGroupObj = sigGenGroupObj(1);
    % Short cuts:
    T_SINE = ps5000aEnuminfo.enPS5000AWaveType.PS5000A_SINE;
    % T_SQUARE = ps5000aEnuminfo.enPS5000AWaveType.PS5000A_SQUARE;
    
    awgBufferSize = get(sigGenGroupObj, 'awgBufferSize');
    x = 0:(2*pi)/(awgBufferSize - 1):2*pi;
    y = normalise(sin(x) + sin(2*x) + sin(3*x));

    % [time, chA, chB] = mrunSimple(device, ti, T_SINE, 0.06, 0, 1000, 2, 2);
    % (60/5.066)
    [time, chA, chB] = mrunArbitrary(device, ti, y, 1, 0.1, 1000, 5, 1);

    chA = mean(chA, 2);

    % Channel A
    figure1 = figure('Name','PicoScope 5000 Series (A API) Example - Rapid Block Mode Capture', ...
        'NumberTitle', 'off');
    plot(time, chA);
    title('Channel A');
    xlabel('Time (s)');
    ylabel('Voltage (mV)');
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

