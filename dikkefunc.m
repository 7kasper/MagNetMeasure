%% Instrument Connection

% Find a VISA-USB object.
fgen = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::0xF4ED::0xEE3A::T0102C22020014::0::INSTR', 'Tag', '');

% Create the VISA-USB object if it does not exist
% otherwise use the object that was found.
if isempty(fgen)
    fgen = visa('KEYSIGHT', 'USB0::0xF4ED::0xEE3A::T0102C22020014::0::INSTR');
else
    fclose(fgen);
    fgen = fgen(1);
end

% Connect to instrument object, obj1.
fopen(fgen);

%code
fprintf(fgen,'C1:OUTP OFF,LOAD,50');
fprintf(fgen,'C1:BSWV WVTP, PULSE');
fprintf(fgen,'C1:BSWV FRQ, 10000');
fprintf(fgen, 'C1:BSWV AMP,5');
fprintf(fgen, 'C1:BSWV DUTY,50');
fprintf(fgen, 'C1:BSWV RISE,15e-9');

%% Loop
frange=1e3:100:1e6;
tout=linspace(0,30,length(frange));
i=1e3;
fprintf(fgen,'C1:OUTP OFF,LOAD,50');
fprintf(fgen,'C1:BSWV WVTP, SINE');
fprintf(fgen,'C1:BSWV FRQ, 1e3');
fprintf(fgen, 'C1:BSWV AMP,10');
% vout=NaN(0,1);
% voutrng=NaN(0,1);
% vinrng=NaN(0,1);
% iout=NaN(0,1);
% ioutrng=NaN(0,1);
% iinrng=NaN(0,1);
% rout=NaN(0,1);
pause(5)
while i<max(frange)+100
%     vin=query(dclo, 'FETCh:VOLT?');
%     voutrng=[voutrng 
    pause(1/length(frange))
    val=['C1:BSWV FRQ, ' num2str(i)];
    fprintf(fgen, val);
%     vin=query(dclo, 'FETCh:VOLT?');
%     iin=query(dclo, 'FETCh:CURRent?');
%     vout=[vout str2num(vin)];
%     iout=[iout str2num(iin)];
%     rout=[rout i];
    i=i+100;
end