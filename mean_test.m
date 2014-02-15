
%% Initialization
SamplesPerFrame = 2048;
FReader = dsp.AudioFileReader('clips/ad1.wav','SamplesPerFrame',SamplesPerFrame);
Fs = FReader.SampleRate;

TimeScope = dsp.TimeScope('SampleRate',Fs,'BufferLength',4*Fs,...
	 'TimeSpan',300,'YLimits',[-0.5 0.5],'ShowGrid',true);

TimeScopeOut = dsp.TimeScope('SampleRate',Fs,'BufferLength',4*Fs,...
	 'TimeSpan',300,'YLimits',[-0.5 0.5],'ShowGrid',true, 'Name', 'Output Time Scope');

Player = dsp.AudioPlayer('SampleRate',Fs);

FWriter = dsp.AudioFileWriter('SampleRate',Fs,...
	 'FileFormat','M4A','Filename', 'output.M4A');
 
%Meaner = dsp.Mean('RunningMean', true);
Meaner = dsp.Mean();

%% Stream
tic;
i=0;
in_commercial = false;
time_last_toggle = 0;

while toc < 300
	 % Read frame from file
	 audioIn = step(FReader);
     
     % Trivial algorithm, scale input audio
	 audioOut = 0.8*audioIn;

	 % View audio waveform
	 step(TimeScope,[audioIn]);

	 % Play resulting audio, if we're not in a commercial
     if (in_commercial==false)
        audioOut = zeros(size(audioOut)); 
     end
     step(Player,audioOut);

    % View waveform of output sound
     step(TimeScopeOut, audioOut);

	 % Write resulting audio
	 %step(FWriter,audioOut);
     
     % Calculate mean
     m = step(Meaner, audioIn);
     m = sum(m,2);
     % check for silence
     if (m==0)
         % if we've found a silence, see if it's been enough time
         if (toc - time_last_toggle > 30)
         in_commercial = ~in_commercial
         time_last_toggle = toc;
         end
     end

end

%% Terminate
release(FReader)
s = [];
release(TimeScope)
s.TimeScope = TimeScope;
release(Player)
release(FWriter)
