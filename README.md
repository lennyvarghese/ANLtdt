# ANL TDT playback code

Code for straightforward audio playback + event sending via TDT RP2.1 or TDT RZ6 systems.
Mostly geared towards auditory EEG applications, where it is often useful to
have an 8-bit word (integer) sent via the digital output at a specified sample.

Features:

* independent channel scaling

* ~~optional masking noise to one or both ears~~ removed in v1.3 (see function 
  help for details)

* ability to specify events to mark on an EEG file as sample numbers and
  integer event values (see example)

* arbitrary event handling (i.e., send any digital value to the TDT at any
  time)

* supports up to 8,380,000 samples (1-channel mode) with up to 2,250 events.

* supports TDT button boxes (inputs 1-4), and returns button presses and
  samples relative to start of audio playback, facilitating accurate reaction 
  time computations

The peak DSP cycle usage at 48 kHz is ~90% when memory buffers are being
accessed.

Example usage
--------------
Initializes the TDT RP2.1 for 1 channel stimuli at 24 kHz, using the voltage
range [-1, 1], and an event duration of 1 ms

```
myTDT = tdt('playback_1channel', 24, [1, 1], 1E-3);
```

Create a stimulus
```
t = 0:(1/myTDT.sampleRate):(10 - 1/myTDT.sampleRate);
chan1Stim = sin(2*pi*1000*t)';
```

Send event "1" when playback starts (sample 1), and another event "2", at
sample 10000, and an event 35 at sample 20000:
```
trigInfo = [ 1, 1; 10000, 2; 20000, 35];
```

Send the stimulus and trigger information to the TDT, then play in blocking mode:
```
myTDT.load_stimulus(chan1Stim, trigInfo);
myTDT.play_blocking();
```

Please refer to examples.m for additional examples.

Version history:

v1.3: Added button box functionality; removed noise functionality. Fixed a
small bug in play_blocking that would cause Matlab to hang.

v1.4: Fixed bug which prevented "normally-closed" button box inputs from registering properly.

v1.5: Added options to allow for speeded TDT communication by using 16-bit stimuli 
