function y = audio_algorithm_peqso(u,tunedparams)
% Copyright 2013 The MathWorks, Inc.
persistent PE1 PE2
if isempty(PE1)
    PE1 = ParametricEQFilter('Bandwidth',2000,'CenterFrequency',3000,'PeakGaindB',6.02);
    PE2 = ParametricEQFilter('Bandwidth',2000,'CenterFrequency',1000,'PeakGaindB',-6.02);
end

[PE1,PE2] = processtunedparams(tunedparams,PE1,PE2);

v = step(PE1,u);

y = step(PE2,v);

%-------------------------------------
function [PE1,PE2] = processtunedparams(tunedparams,PE1,PE2)

if ~isnan(tunedparams.CenterFrequency)
    PE1.CenterFrequency = tunedparams.CenterFrequency;
end

if ~isnan(tunedparams.Bandwidth)
    PE1.Bandwidth = tunedparams.Bandwidth;
end

if ~isnan(tunedparams.Gain)
    PE1.PeakGaindB = tunedparams.Gain;
end

if ~isnan(tunedparams.CenterFrequency2)
    PE2.CenterFrequency = tunedparams.CenterFrequency2;
end

if ~isnan(tunedparams.Bandwidth2)
    PE2.Bandwidth = tunedparams.Bandwidth2;
end

if ~isnan(tunedparams.Gain2)
    PE2.PeakGaindB = tunedparams.Gain2;
end
