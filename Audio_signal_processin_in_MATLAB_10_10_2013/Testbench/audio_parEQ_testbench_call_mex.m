function [s,t] = audio_parEQ_testbench(playaudio, showscopes)
% Copyright 2013 The MathWorks, Inc.

if nargin < 1
    playaudio = true;
end
if nargin < 2
    showscopes = true;
end

%% Initialization
SamplesPerFrame = 1024;
FReader = dsp.AudioFileReader('guitar2min.ogg','SamplesPerFrame',SamplesPerFrame);
Fs = FReader.SampleRate;
TransferFuncEstimate = dsp.TransferFunctionEstimator('SampleRate',Fs,...
	                                                 'FrequencyRange',...
                                                     'onesided','SpectralAverages',50);
MyArrayPlot = dsp.ArrayPlot('PlotType','Line',...
	                      'YLimits',[-20 20],'SampleIncrement',Fs/(2*512),...
	                      'YLabel','Magnitude (dB)','XLabel','Frequency (Hz)',...
	                      'Title','Transfer Function Estimate');
Speaker = dsp.AudioPlayer('SampleRate',Fs);

param = ParamInitiate;
% Create the UI and pass it the parameters
GUI = CreateParamTuningGUI(param, 'Tuning');

%% Stream
pauseSim = false;
clear UnpackUDP;

tic;
while ~isDone(FReader)
	 if ~pauseSim
		 % Read frame from file
		 audioIn = step(FReader);
     end
     [pauseSim,stopSim,tunedparams] = callbacks(param);
	 
     % Audio processing algorithm - replace with custom algorithm
	  audioOut = audio_algorithm_peqso_mex(audioIn,tunedparams);
     
     %If "stop Simulation" button is pressed
	 if stopSim,break; end
     % If "Pause Simulation" button is pressed
	 if pauseSim, drawnow; continue; end

     if showscopes
         % Estimate transfer function
         H = step(TransferFuncEstimate,audioIn,audioOut);
         
         % View estimated transfer function
         step(MyArrayPlot,20*log10(abs(H)));
     end

     if playaudio
         % Play resulting audio
         step(Speaker,audioOut);
     end

end

%% Terminate
release(FReader)
s = [];
release(TransferFuncEstimate)
release(MyArrayPlot)
s.ArrPlt = MyArrayPlot;
release(Speaker)
close(GUI);

%% Measure performance
display('Toc is getting executed');
t = toc;