
%% Initialization
SamplesPerFrame = 2048;
%FReader = dsp.AudioFileReader('clips/ad1.wav','SamplesPerFrame',SamplesPerFrame, ...
%    'PlayCount',1);

FReader = dsp.AudioRecorder('SampleRate', 8000, 'SamplesPerFrame',SamplesPerFrame,...
    'OutputDataType','double', 'DeviceName', 'Soundflower (2ch)');

Fs = FReader.SampleRate;

%TimeScope = dsp.TimeScope('SampleRate',Fs,'BufferLength',4*Fs,...
%	 'TimeSpan',60,'YLimits',[-0.5 0.5],'ShowGrid',true);

%TimeScopeOut = dsp.TimeScope('SampleRate',Fs,'BufferLength',4*Fs,...
%	 'TimeSpan',300,'YLimits',[-0.5 0.5],'ShowGrid',true, 'Name', 'Output Time Scope');

%Player = dsp.AudioPlayer('SampleRate',Fs, 'DeviceName', 'Built-in Output');

Meaner = dsp.Mean();

%% Variables to be tuned
max_comm_length = 100; % Maximum length of a single commercial
max_comm_block_length = 130; % Maximum length of a block of commercials
threshold = 1; % Ignore detected silences if it's been < threshold
min_comm_block_length = 90;

%% Initialize features for figuring stuff out
in_commercial = false;
last_toggle = 0;
last_silence = 0;
time_since_start = 0; % Currently unused
silence_length = 0; % Keep track of how long a given silence is

%% Testing something
% [status, result] = system('osascript -e "set Volume 1"');
% [status, result] = system('osascript -e "output volume of (get volume settings)"');
% test = result == 10

%% Stream
tic;

while ~isDone(FReader)
    % Read frame from file
    audioIn = step(FReader);
    
    % Trivial algorithm, scale input audio
    %audioOut = 0.8*audioIn;
    
    % View audio waveform
    %step(TimeScope,audioIn);
    
    % Play resulting audio, if we're not in a commercial
    %if (in_commercial==true)
    %   audioOut = zeros(size(audioOut));
    %end
    %step(Player,audioOut);
    
    % View waveform of output sound
    % step(TimeScopeOut, audioOut);
    
    % Calculate mean
    m = step(Meaner, audioIn);
    m = sum(m,2);
    
    % If we're sure we're not in a commercial, fix it!
    % Basically, if there hasn't been a silence in a long time,
    % we must be in the show.
    if (in_commercial)
        if ((toc - last_silence) > max_comm_length)
            t = toc - last_silence;
            in_commercial = false;
            last_toggle = toc;
            [status, result] = system('osascript -e "set Volume 10"');
            'Max comm length exceeded - switching to show'
        end
    end
    
    % check for silence
    if (m==0)
        % SILENCE DETECTED
        'Silence detected'
        % increment silence length
        silence_length = silence_length + 1;
        
        % If it's part of a long silence, assume just buffering and keep going
%         if (silence_length >= 3)
%             last_silence = toc;
%             'Detected buffering'
%             continue;
%         end
        
        % Check for SHOW->COMMERCIAL transition:
        % If time since last toggle is definitely longer than a block
        % of commercials, this silence must be a show-comm transition
        'Time since last toggle: '
        time = toc-last_toggle
        if (~in_commercial && (toc - last_toggle > max_comm_block_length)) 
            in_commercial = true;
            [~, ~] = system('osascript -e "set Volume 1"');
            last_toggle = toc;
            % last_silence = toc;
            'Detected show->commercial transition'
        end
        
        % Check for COMMERCIAL->SHOW transition:
        % If current commercial block has been going for 90+ seconds,
        % assume going back to a show.
        if (in_commercial && (toc-last_toggle > min_comm_block_length))
            in_commercial = false;
            [~, ~] = system('osascript -e "set Volume 10"');
            last_toggle = toc;
            'Detected commercial->show transition'
        end
        
        % Set current time to be the last silence found
        last_silence = toc;
        
    else
        % Not a silence, so reset silence length
        silence_length = 0;
    end
    
    % Check that we're not arguing with the user
    [status, result] = system('osascript -e "output volume of (get volume settings)"');
    result = str2num(result(127:129));
    % Result is 14 when after calling 'set Volume 1'.  idk why
    if (in_commercial && result ~= 14)
       % We think we're in a commercial, but the user has increased the volume 
       in_commercial = false;
       'User changed volume - change in_commercial to false'
    end
    
end

%% Terminate
release(FReader)
s = [];
release(TimeScope)
s.TimeScope = TimeScope;
release(Player)
