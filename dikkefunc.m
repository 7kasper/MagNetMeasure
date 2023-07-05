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

% Connect to instrument object, fgen.
awgBufferSize = 8e6; % We just do the maximum that we can.
fgen.OutputBufferSize = awgBufferSize*3;
fopen(fgen);

x = 0:(2*pi)/(awgBufferSize - 1):2*pi;
y = int16(round(normalise(sin(x) + sin(2*x)) * ((2^15)-1)));
rrr = char(typecast(y,'uint8'));



fprintf(fgen,'*RST');
ph = 0.0;

%visa_string = sprintf('C1:WVDT:BLOCK #281,WVNM,wave1,FREQ,2000.0,AMPL,4.0,OFST,0.0,PHASE,0.0,WAVEDATA,%s',data);
fwrite(fgen, sprintf('C1:WVDT WVNM,wave2,FREQ,%s,AMPL,%s,OFST,%s,PHASE,%s,WAVEDATA,%s',rrr));
fwrite(fgen,'C1:ARWV NAME,wave2');
fwrite(fgen,'C1:OUTP OFF');
fwrite(fgen,'C1:OUTP ON');



% fprintf(fgen, ['C1:WVDT WVNM,wave1,FREQ,2000.0,AMPL,4.0,OFST,0.0,PHASE,0.0,WAVEDATA,' rrr]);
% fprintf(fgen, 'C1:ARWV NAME,wave1');
% 
% fprintf(fgen, 'WVDT? USER,wave1');
% outputbuffer = fscanf(fgen); disp(outputbuffer);



%code
% fprintf(fgen,'C1:OUTP OFF,LOAD,50');
% fprintf(fgen,'C1:BSWV WVTP, PULSE');
% fprintf(fgen,'C1:BSWV FRQ, 1000');
% fprintf(fgen, 'C1:BSWV AMP,5');
% fprintf(fgen, 'C1:BSWV DUTY,50');
% fprintf(fgen, 'C1:BSWV RISE,15e-9');
% fprintf(fgen, 'C1:OUTP OFF');




% %% Loop
% frange=1e3:100:1e6;
% tout=linspace(0,30,length(frange));
% i=1e3;
% fprintf(fgen,'C1:OUTP OFF,LOAD,50');
% fprintf(fgen,'C1:BSWV WVTP, SINE');
% fprintf(fgen,'C1:BSWV FRQ, 1e3');
% fprintf(fgen, 'C1:BSWV AMP,10');
% % vout=NaN(0,1);
% % voutrng=NaN(0,1);
% % vinrng=NaN(0,1);
% % iout=NaN(0,1);
% % ioutrng=NaN(0,1);
% % iinrng=NaN(0,1);
% % rout=NaN(0,1);
% pause(5)
% while i<max(frange)+100
% %     vin=query(dclo, 'FETCh:VOLT?');
% %     voutrng=[voutrng 
%     pause(1/length(frange))
%     val=['C1:BSWV FRQ, ' num2str(i)];
%     fprintf(fgen, val);
% %     vin=query(dclo, 'FETCh:VOLT?');
% %     iin=query(dclo, 'FETCh:CURRent?');
% %     vout=[vout str2num(vin)];
% %     iout=[iout str2num(iin)];
% %     rout=[rout i];
%     i=i+100;
% end