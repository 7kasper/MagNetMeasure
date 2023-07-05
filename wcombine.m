function [time, out] = wcombine(timeIn, in, waveforms)
    % wcombine.m Combines multiple waveforms into a super waveform.
    % Inputs:
    %   timeIn : time-data of original waveform.
    %     in : original waveform data.
    %   waveforms: How many waveforms are in the data.
    % Outputs:
    %   time: vector of measurepoints timeindex. Length is length(timeIn)/waveforms
    %    out: super waveform data.

    % Reshape into matrix of waveforms
    timeBase = numel(timeIn)/waveforms
    q = reshape(in, [timeBase waveforms]);
    out = mean(q, 2); % just mean in right dimension.
    time = timeIn(1:timeBase);
end