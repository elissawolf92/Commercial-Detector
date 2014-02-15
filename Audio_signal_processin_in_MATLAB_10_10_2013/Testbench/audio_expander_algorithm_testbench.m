function s = audio_expander_algorithm_testbench

%% Initialization
% Copyright 2013 The MathWorks, Inc.
SamplesPerFrame = 1024;
Microphone = dsp.AudioRecorder('SamplesPerFrame',SamplesPerFrame,...
	 'OutputDataType','double');
Fs = Microphone.SampleRate;

MyTimeScope = dsp.TimeScope('SampleRate',Fs,'BufferLength',2*Fs,...
	 'TimeSpan',1,'YLimits',[-0.5 0.5],'ShowGrid',true);
 Spectra = dsp.SpectrumAnalyzer('SampleRate',Fs,...
	 'PlotAsTwoSidedSpectrum',false,'SpectralAverages',20,'FrequencyScale','Linear');
 
Fpass = 4750;    % Passband Frequency
Fstop = 5250;   % Stopband Frequency
Apass = 0.5;    % Passband Ripple (dB)
Astop = 80;     % Stopband Attenuation (dB)
Fs    = 44100;  % Sampling Frequency

h = fdesign.lowpass('fp,fst,ap,ast', Fpass, Fstop, Apass, Astop, Fs);

FIR = design(h, 'equiripple', ...
    'MinOrder', 'any', ...
    'StopbandShape', 'flat', ...
    'SystemObject', true);

%% Stream
z = zeros(Microphone.SamplesPerFrame,Microphone.NumChannels);
tic;
while toc < 15
	 % Read frame from microphone
	 audioIn = step(Microphone);
               step(Spectra,audioIn)

	 % Dynamic range expansion
     [audioOut,a] = expander_algorithm(audioIn,FIR,z);  

	 % View audio waveform
	  step(MyTimeScope,[audioIn,audioOut]);

end

%% Terminate
release(Microphone)
s = [];
release(MyTimeScope)
release(Spectra)
s.TimeScope = MyTimeScope;
