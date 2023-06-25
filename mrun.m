function [] = mrun(device, ti)
    
    % Local setup:
    PS5000aConfig;
    % sigGenGroupObj = get(device, 'Signalgenerator');
    % sigGenGroupObj = sigGenGroupObj(1);
    % Short cuts:
    T_SINE = ps5000aEnuminfo.enPS5000AWaveType.PS5000A_SINE;
    % T_SQUARE = ps5000aEnuminfo.enPS5000AWaveType.PS5000A_SQUARE;
    
    % awgBufferSize = get(sigGenGroupObj, 'awgBufferSize');
    % x = 0:(2*pi)/(awgBufferSize - 1):2*pi;
    % y = normalise(sin(x) + sin(2*x) + sin(3*x));

    mrunSimple(device, ti, T_SINE, 2000, 0, 1000, 1);
    % mrunArbitrary(device, y, (60/5.066), 0, 1000:1000:10000, 5);

end

