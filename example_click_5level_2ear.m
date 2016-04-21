% ABR 5 level demo
% updated for version 1.6

% the scaling values here are voltages I determined to get a specified SPL for
% the clicks being presented via the earphones I want to use
myTdt = tdt('playback_2channel', 48, [1.6*db2mag(12), 1.65*db2mag(12)], ...
            'triggerDuration', 0.002);

% need to check that the HB7 gain knob is at the right setting
check = 'notok';
while ~strcmpi(check, 'ok')
    check = input('set hb7 to -12 and type ok: ', 's');
end

% full scale: 100 dB click, peak-peak equivalent (roughly)
peakClickHeight = 1;
clickSamples = round(80E-6*myTdt.sampleRate);

% present the stimuli at 5 levels, in alternating polarities
% trig values 1-5 are positive, 0, -10, -20, -30, -40 dB
% 6-10 are negative, 0, -10, -20, -30, -40 dB 
allPolarities = repmat([1, 1, 1, 1, 1, -1, -1, -1, -1, -1], 1, 100);
allLevels = repmat([db2mag(0), db2mag(-10), db2mag(-20), db2mag(-30), db2mag(-40),...
                 db2mag(0), db2mag(-10), db2mag(-20), db2mag(-30), db2mag(-40)], 1, 100);
allTrigVals = repmat([1, 2, 3, 4, 5, 6, 7, 8, 9, 10], 1, 100);

% present stimulus one ear at a time
% each "block" can be max ~ 80 seconds
for channel = [1, 2, 2, 1, 1, 2, 2, 1]
    for rep = 1:5
        randomOrder = randperm(1000);
        polarities = allPolarities(randomOrder);
        levels = allLevels(randomOrder);
        trigVals = allTrigVals(randomOrder);
        % jitter the ISI to be between 50-80 ms (see below)
        isis = rand(1, 1000)*0.03;
        
        stimulus = zeros(round(myTdt.sampleRate*81), 2);
        trigInfo = zeros(1000, 2);

        pos = 1;
        for x = 1:1000
            stimulus(pos:(pos+clickSamples-1), channel) = polarities(x)*levels(x);
            if channel == 2
                trig = trigVals(x) + 100;
            else
                trig = trigVals(x);
            end
            trigInfo(x, :) = [pos, trig];
            pos = pos + round((0.05 + isis(x))*myTdt.sampleRate);
        end
        
        % chop off the end of the stimulus I don't need
        stimulus(pos:end, :) = [];

        % load, and play back; hold up matlab while playing
        myTdt.load_stimulus(stimulus, trigInfo);
        myTdt.play_blocking();

        % reset the TDT before proceeding to next iteration
        myTdt.reset();
    end
end
