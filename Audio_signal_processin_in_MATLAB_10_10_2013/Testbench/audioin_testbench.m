%% Initialization
% Copyright 2013 The MathWorks, Inc.
SamplesPerFrame = 1024;
%Microphone = dsp.AudioRecorder('SamplesPerFrame',SamplesPerFrame,...
%	                           'OutputDataType','double');
Microphone = dsp.AudioFileReader('guitar10min.ogg','SamplesPerFrame',SamplesPerFrame);
Fs = Microphone.SampleRate;

Spectra = dsp.SpectrumAnalyzer('SampleRate',Fs,'PlotAsTwoSidedSpectrum',false,...
                               'SpectralAverages',20,'FrequencyScale','Log');

%% Stream
tic;
while toc < 20
	 % Read frame from microphone
	 audioIn = step(Microphone);

	 % View audio spectrum
	 step(Spectra,audioIn);
end

%% Terminate
release(Microphone)
s = [];
release(Spectra)
s.Spectra = Spectra;
