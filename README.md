# ANL TDT playback code

Code for straightforward audio playback + event sending via TDT RP2.1 system. Mostly geared towards auditory EEG applications, where an 8-bit word (integer) is sent via the digital output at a specified sample.

Features:

* independent channel scaling

* optional masking noise to one or both ears

* ability to specify events to mark on an EEG file as sample numbers and integer event values (see example)

* arbitrary event handling (i.e., send any digital value to the TDT at any time)

* Supports up to 8,384,200 samples (1-channel mode) with up to ~3000 events.

Peak DSP cycle usage at 48 kHz with buffers being accessed is approximately 85%.

Example usage
--------------
Initializes the TDT RP2.1 for 1 channel stimuli at 24 kHz, using the voltage range [-1, 1], an event duration of 1 ms, and masking noise in the second channel at -20 dB RMS re: full scale voltage:
```
myTDT = tdt('playback_1channel', 24, [1, 1], 1E-3, [-Inf, -20]);
```

Create a stimulus
```
t = 0:(1/myTDT.sampleRate):(10 - 1/myTDT.sampleRate);
chan1Stim = sin(2*pi*1000*t)';
```

Send event "1" when playback starts (sample 1), and another event "2", at sample 10000, and an event 35 at sample 20000:
```
trigInfo = [ 1, 1; 10000, 2; 20000, 35];
```

Send the stimulus and trigger information to the TDT, then play in blocking mode:
```
myTDT.load_stimulus(chan1Stim, trigInfo);
myTDT.play_blocking();
```

Please refer to examples.m for additional examples.
