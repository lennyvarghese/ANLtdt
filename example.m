%% Initialization and clean shutdown examples

% set max/min on both channel to 0.1 V; no background noise, default trigger
% durations (5 ms), 24 kHz sample rate
myTDT = tdt('playback', 24, 0.1, [], -Inf);
pause(1)
myTDT.close();
clear myTDT

% set channel scaling to 0.2V in left channel, 0.3V in right channel; set
% trigger durations to 10 ms; sample rate 48Khz wait 1 second, and close out.
myTDT = tdt('playback', 48, [0.2, 0.3], 0.01);
pause(1);
myTDT.close()
clear myTDT

% set channel scaling to 1.1 V, 1 ms trigger durations, turn on continuous
% background noise at -70 dB re: 1V RMS; wait 1 second, then close out.
myTDT = tdt('playback', 48, 1.1, 1E-3, -70);
pause(1);
myTDT.close()
clear myTDT

% set channel scaling to 1.1V in channel 1 and 1.0V in channel 2, 1 ms trigger
% durations, turn on continuous background noise in left ear at -60 dB re: 1V
% RMS but no noise in the other ear.  leave this one instance open for the
% other examples.
myTDT = tdt('playback', 48, [1.1, 1], 1E-3, [-Inf, -60]);
pause(1);
myTDT.close()
clear myTDT




%% Stimulus creation and transfer to TDT

myTDT = tdt('playback', 24, [1, 1], 1E-3, [-Inf, -20]);

% create a stimulus
t = 0:(1/myTDT.sampleRate):(10 - 1/myTDT.sampleRate);
chan1Stim = sin(2*pi*1000*t);
chan2Stim = zeros(size(chan1Stim));

% stimulus must be in 2 channel (row vector) format
x = [chan1Stim', chan2Stim'];
size(x)

% Send event "1" when playback starts (sample 1), and another event "2"
% at sample 10000, and an event 35 at sample 20000
trigInfo = [   1,   1;
            10000,  2;
            20000, 35];

% send the stimulus and trigger information to the TDT
myTDT.load_stimulus(x, trigInfo);





%% Playback examples

% play the entire duration; this is non-blocking, so will need a pause()-type
% command that accounts for the entire stimulus duration
myTDT.play();
pause(myTDT.stimSize / myTDT.sampleRate + 0.05);


% rewind, but don't reset the buffers
myTDT.rewind();

% play the first 10000 samples and stop
myTDT.play(10000);

% rewind and clear buffers
myTDT.reset();

% play the stimulus, stop after 100 ms, then pick up again from that point, and
% stop again at sample 40000
myTDT.load_stimulus(x, trigInfo);

myTDT.play();
pause(0.1);
myTDT.pause();
pause(0.5);
bufferIdx = myTDT.get_current_sample();
myTDT.play(40000)
pause( 0.01 + (40000 - bufferIdx) / myTDT.sampleRate )
