%% Initialization and clean shutdown examples
% updated for version 1.2

% set max/min on channels to 0.1 V; no background noise, default trigger
% durations (5 ms), 24 kHz sample rate
myTDT = tdt('playback_1channel', 24, 0.1, [], -Inf);
pause(1)
clear myTDT

% set channel scaling to 0.2V in left channel, 0.3V in right channel; set
% trigger durations to 10 ms; sample rate 48Khz; opposite-ear masking noise at
% -60 dB.
myTDT = tdt('playback_1channel', 48, [0.2, 0.3], 0.01, [-Inf, -60]);
pause(1);
clear myTDT

% set both channels' scaling to 1.1 V, 1 ms trigger durations, turn on continuous
% background noise at -70 dB re: 1V RMS; wait 1 second, then clear the object.
myTDT = tdt('playback_2channel', 48, 1.1, 1E-3, -70);
pause(1);
clear myTDT

% set channel scaling to 1.1V in channel 1 and 1.0V in channel 2, 1 ms trigger
% durations, turn on continuous background noise in right ear at -60 dB re: 1V
% RMS but no noise in the other ear.  
myTDT = tdt('playback_2channel', 48, [1.1, 1], 1E-3, [-Inf, -60]);
pause(1);
clear myTDT



%% Stimulus creation and transfer to TDT

myTDT = tdt('playback_2channel', 24, [1, 1], 1E-3, [-Inf, -20]);

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

myTDT.play_blocking();
myTDT.rewind();

% play the first 10000 samples while blocking and stop
myTDT.play_blocking(10000);

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
myTDT
