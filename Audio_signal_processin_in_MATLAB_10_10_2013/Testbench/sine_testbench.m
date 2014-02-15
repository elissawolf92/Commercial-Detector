%% Initialization
% Copyright 2013 The MathWorks, Inc.
SamplesPerFrame = 100;
Fs = 44100;
MySineWave = dsp.SineWave('SamplesPerFrame',SamplesPerFrame,...
      'Amplitude',[2.5, 3.5],...
      'PhaseOffset',[0 pi/3],...
	 'SampleRate',Fs,'Frequency',[800,1000]);

 MyTimeScope = dsp.TimeScope('SampleRate',Fs,'BufferLength',2*Fs,...
	 'TimeSpan',0.0046,'YLimits',[-4 4],'ShowGrid',true);

%% Step
tic;
while toc<30
x = step(MySineWave);
    step(MyTimeScope,x);
end
 %% Terminate
release(MySineWave)
release(MyTimeScope)
