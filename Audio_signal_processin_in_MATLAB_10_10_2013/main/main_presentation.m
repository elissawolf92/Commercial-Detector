%% Demo of final 3-band parametric EQ
% Copyright 2013 The MathWorks, Inc.

clear all;
clear HelperUnpackUDP
HelperAudioEqualization

%% Sine Wave Testbench: Generating an audio tone from within MATLAB
clear all;clc
edit sine_testbench

%% Real-time Testbench: Importing live audio data into MATLAB from microphone
clear all;clc
edit audioin_testbench

%% Real-time Testbench: Reading audio from file and playing through speakers
% Support for wav, mp3, m4a/mp4, ogg, flac
clear all;clc
edit audiofile_testbench

%% Design a lowpass filter - we will need this in the next example
filterbuilder

%% Custom Algorithm: Dynamic Range Expander
clear all;clc
edit audio_expander_algorithm_testbench

%% 2-band Parametric EQ - functional and custom System obj; simulation vs. code generation
clear all;clc
edit audio_parEQ_testbench


