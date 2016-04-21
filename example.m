%% Initialization and clean shutdown examples
% updated for version 1.6

% set max/min on channels to 0.1 V; no background noise, default trigger
% durations (5 ms) and button hold durations (200 ms) 24 kHz sample rate
myTDT = tdt('playback_1channel', 24, 0.1);
pause(1)
clear myTDT

% set channel scaling to 0.2V in left channel, 0.3V in right channel; set
% trigger durations to 10 ms, and button hold duration to 100 ms; sample rate 
% 48Khz
myTDT = tdt('playback_1channel', 48, [0.2, 0.3], 'triggerDuration', 0.01, ...
    'buttonHoldDuration', 0.1);
pause(1);
clear myTDT

% set both channels' scaling to 1.1 V, 1 ms trigger durations, turn on
% continuous wait 1 second, then clear the object. use the "16bit" version
% of the 2-channel circuit
myTDT = tdt('playback_2channel_16bit', 48, [1.1, 1.1],...
            'triggerDuration', 1E-3);
pause(1);
clear myTDT

% set channel scaling to 1.1V in channel 1 and 1.0V in channel 2, 100 ms
% button hold duration
myTDT = tdt('playback_2channel', 48, [1.1, 1], 'buttonHoldDuration', 1E-3);
pause(1);
clear myTDT


%% Stimulus creation and transfer to TDT
clear myTDT;
myTDT = tdt('playback_2channel', 24, [1, 1], 'triggerDuration', 1E-3);

% create a stimulus
t = 0:(1/myTDT.sampleRate):(10 - 1/myTDT.sampleRate);
chan1Stim = sin(2*pi*1000*t);
chan2Stim = zeros(size(chan1Stim));

% stimulus must be in 2 channel (row vector) format
x = [chan1Stim', chan2Stim'];
size(x)

% Send event "1" when playback starts (sample 1), and another event "2" at
% sample 10000, and an event 35 at sample 20000
trigInfo = [   1,   1;
            10000,  2;
            20000, 35];

% send the stimulus and trigger information to the TDT
myTDT.load_stimulus(x, trigInfo);

%% Playback examples
% play the entire stimulus (with debug mode on)
myTDT.play_blocking([], 1);
% pull any button presses that occurred during playback
% note: if this does not return NaN when no buttons were pressed, or if no
% buttons are connected, then the xor value needs to be changed in the
% object constructor call.
[buttonPresses, buttonPressSamples] = myTDT.get_button_presses()
myTDT.rewind();

% play the first 10000 samples while blocking and stop, also with debug
% mode on
myTDT.play_blocking(10000, 1);

% pull any button presses that occurred since the last rewind
[buttonPresses, buttonPressSamples] = myTDT.get_button_presses();

% play the rest of it, with debug mode on
myTDT.play_blocking([], 1);

% rewind and clear buffers
myTDT.reset();

% since the buffer was cleared when using reset, must re-load the stimulus and
% triggers
myTDT.load_stimulus(x, trigInfo);

% play the stimulus, stop after 100 ms, then pick up again from that point, and
% stop again at sample 40000
myTDT.play(round(0.1*myTDT.sampleRate));
pause(0.1);
myTDT.pause();
pause(0.5);
myTDT.play(40000)
pause(1);
myTDT.get_current_sample()
pause(2);
clear myTDT;

%% some timing tests 
% (how long it takes to load a 10s stimulus to the TDT using various
% paradigm settings)

disp('Using 48.8 kHz, 32 bit data transfer')
myTDT = tdt('playback_2channel', 48, [1, 1]);
% create a stimulus
t = 0:(1/myTDT.sampleRate):(10 - 1/myTDT.sampleRate);
chan1Stim = sin(2*pi*1000*t);
chan2Stim = zeros(size(chan1Stim));
x = [chan1Stim', chan2Stim'];

tic
myTDT.load_stimulus(x);
toc
clear myTDT

disp('Using 48.8 kHz, 16 bit data transfer')
myTDT = tdt('playback_2channel_16bit', 48, [1, 1]);
% create a stimulus
t = 0:(1/myTDT.sampleRate):(10 - 1/myTDT.sampleRate);
chan1Stim = sin(2*pi*1000*t);
chan2Stim = zeros(size(chan1Stim));
x = [chan1Stim', chan2Stim'];
tic
myTDT.load_stimulus(x);
toc
clear myTDT

disp('Using 24.4 kHz, 32 bit data transfer')
myTDT = tdt('playback_2channel', 24, [1, 1]);
% create a stimulus
t = 0:(1/myTDT.sampleRate):(10 - 1/myTDT.sampleRate);
chan1Stim = sin(2*pi*1000*t);
chan2Stim = zeros(size(chan1Stim));
x = [chan1Stim', chan2Stim'];
tic
myTDT.load_stimulus(x);
toc
clear myTDT

disp('Using 24.4 kHz, 16 bit data transfer')
myTDT = tdt('playback_2channel_16bit', 24, [1, 1]);
% create a stimulus
t = 0:(1/myTDT.sampleRate):(10 - 1/myTDT.sampleRate);
chan1Stim = sin(2*pi*1000*t);
chan2Stim = zeros(size(chan1Stim));
x = [chan1Stim', chan2Stim'];
tic
myTDT.load_stimulus(x);
toc
clear myTDT