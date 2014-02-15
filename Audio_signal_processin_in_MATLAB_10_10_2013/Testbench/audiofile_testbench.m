function s = audiofile_testbench
% Copyright 2013 The MathWorks, Inc.
%% Initialization
SamplesPerFrame = 1024;
FReader = dsp.AudioFileReader('guitar10min.ogg','SamplesPerFrame',SamplesPerFrame);
Fs = FReader.SampleRate;

TimeScope = dsp.TimeScope('SampleRate',Fs,'BufferLength',4*Fs,...
	 'TimeSpan',1,'YLimits',[-0.5 0.5],'ShowGrid',true);



Player = dsp.AudioPlayer('SampleRate',Fs);

FWriter = dsp.AudioFileWriter('SampleRate',Fs,...
	 'FileFormat','M4A','Filename', 'output.M4A');

%% Stream
tic;
while toc < 30
	 % Read frame from file
	 audioIn = step(FReader);
     
     % Trivial algorithm, scale input audio
	 audioOut = 0.8*audioIn;

	 % View audio waveform
	 step(TimeScope,[audioIn,audioOut]);

	 % Play resulting audio
	 step(Player,audioOut);

	 % Write resulting audio
	 step(FWriter,audioOut);

end

%% Terminate
release(FReader)
s = [];
release(TimeScope)
s.TimeScope = TimeScope;
release(Player)
release(FWriter)
