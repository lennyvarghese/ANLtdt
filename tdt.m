classdef tdt
% tdtObject = tdt([channel1Scale, channel2Scale], figNum=99999)
%
% creates a new tdt object, with max/min ouptut voltage specified
% by default, creates the ActiveX figure as figure number 99999;
% specify an integer second argument if for some reason you want
% another value.
%
% properties:
%
% RP - the "usual" RP object from which TDT functions are accessed
%
% f1 - the figure number used for ActiveX communication
%
% sampleRate - the sample rate at which the RP2/RP2.1 operates 
%
% maxBufferSize - the maximum number of samples that can be handled by
% the circuit without further input from the user. The circuit is
% limited to 4E6 32-bit floating point numbers, per channel. 
%
% currentBufferIdx - the current sample number in the audio buffers
%
% channel1Scale - the scaling value x mapping floating point values
% between [-1,1] to [-x,x] for channel 1
%
% channel2Scale - the scaling value x mapping floating point values
% between [-1,1] to [-x,x] for channel 2
%
%
% class methods: 
%
% prepare_stimulus
% play
% stop
%
% last updated 2015-01-31, LAV, lennyv_at_bu_dot_edu

    properties
        RP
        f1
        sampleRate
        maxBufferSize
        channel1Scale
        channel2Scale
    end

    methods
        function obj = tdt(scaling, figNum)
            
            if nargin < 1 || numel(scaling) ~= 2 
                error('Scaling factors must be specified for each channel')
            end

            if nargin < 2 
                figNum = 99999;
            end
            
            % Start ActiveX controls and hides the figure at the start of each
            % block
            obj.f1 = figure(figNum);
            set(obj.f1,'Position', [5 5 30 30], 'Visible', 'off');
            obj.RP = actxcontrol('RPco.x', [5 5 30 30], obj.f1);
            
            %change argument to 'GB' or 'USB' depending on TDT setup
            obj.RP.ConnectRP2('USB', 1); 
            %Clears all the Buffers and circuits on that RP2
            obj.RP.ClearCOF;
            %Loads circuit
            obj.RP.LoadCOFsf('playback.rcx',3);

            % Start circuit and get status. 
            % If Status returns 7, everything is working.
            obj.RP.Run;

            if obj.RP.GetStatus ~= 7
                error('TDT connection error. Try rebooting the TDT.');
            end
            
            % zero tag the buffer
            obj.RP.ZeroTag('audioChannel1');
            obj.RP.ZeroTag('audioChannel2');
            obj.RP.ZeroTag('triggerIdx')
            obj.RP.ZeroTag('triggerVals')
            obj.RP.ZeroTag('triggerDurations')
            obj.RP.ZeroTag('stopSample')
            
            obj.channel1Scale = single(scaling(1));
            obj.channel2Scale = single(scaling(2));
            
            obj.sampleRate = obj.RP.GetSFreq();
 
            obj.RP.SetTagVal('headphoneScaler1', obj.channel1Scale);
            obj.RP.SetTagVal('headphoneScaler2', obj.channel2Scale);
            
            fprintf('Channel 1, [-1.0, 1.0] --> [-%2.4f, %2.4f] V\n', ...
                 obj.channel1Scale, obj.channel1Scale);
            fprintf('Channel 2, [-1.0, 1.0] --> [-%2.4f, %2.4f] V\n', ...
                 obj.channel2Scale, obj.channel2Scale);

            obj.maxBufferSize = 4.185E6;
        end

        function prepare_stimulus(obj, audioData, triggerInfo)
            % prepare_stimulus(audioData, triggerInfo) function to load
            % stimulus and triggers to TDT RP2 "playback.rcx"
            %
            % RP: the TDT RP object, returned from "initialize_tdt.m"
            % audioDataL: a 1D array specifying audio data for channel 1 (L) **
            % See note 1 audioDataR: a 1D array specifying audio data for
            % channel 2 (R) ** See note 1 triggerInfo: an n x 3 array
            % specifying index, value, duration tuples to send a digital "word"
            % value at the specified sample of playback for the specified
            % duration (in s). ** see note 2 
            %
            % note 1: audioDataL and audioDataR must be limited to [-1, 1].
            % This function will downconvert the arrays to single-precision
            % prior to writing to the TDT if they are not already stored as
            % single precision. By default, the circuit will apply a 5 ms
            % cosine-squared ramp to the stimuli when "play" and "stop" are
            % called. To avoid having the cosine ramp alter a very short
            % stimulus (say, a click), pad the stimulus with at least 245 "0"
            % values on either end (corresponding to 5 ms at the default
            % 48828.125 Hz sample rate).
            %
            % note 2: Trigger samples should be specified using Matlab index
            % style, i.e., the first sample of audio is sample 1. Values should
            % be between 0-255, corresponding to the 8 bit precision of the
            % digital out component on the RP2.  Duration is in seconds. It
            % should be obvious that all of these values must be positive.
            %
            % last updated: 2015-02-11, LAV, lennyv_at_bu_dot_edu
            
            
            %%%%%%%%%%%%%%%%%%%%
            % input validation %
            %%%%%%%%%%%%%%%%%%%%
            
            if size(audioData, 2) > obj.maxBufferSize
                error('Audio data exceeds maximum buffer size.')
            end
            
            if nargin < 3
                triggerInfo = [];
            else
                if (size(triggerInfo, 2) ~= 3) || ...
                    (length(size(triggerInfo)) ~= 2) || ...
                    any(triggerInfo(:) < 0)
            
                    error(['Trigger info must be specified as',...
                          '[idx, val, dur], array, and the values '...
                          'should all be positive.'])
                end
            end
            
            % convert down to single precision floating point, 
            % since that's what the TDT natively uses for DAC
            if ~isa(audioData, 'single')
                audioData = single(audioData);
            end
            
            if ~isempty(triggerInfo)
                triggerIdx = int32(triggerInfo(:, 1));
                triggerVals = int32(triggerInfo(:, 2));
                triggerDurations = single(triggerInfo(:,3));
            else
                triggerIdx = int32(0);
                triggerVals = int32(0);
                triggerDurations = single(0);
            end
            
            if (any(triggerVals > 255) || (any(triggerVals < 0)))
                error('Trigger values must be between 0 and 255.')
            end
            
            if (any(triggerIdx > obj.maxBufferSize) || (any(triggerVals < 1)))
                error('Trigger index must be smaller than max buffer size.')
            end
            
            if (any(triggerDurations < 0))
                error('Trigger durations should be positive.')
            end
                    
            if any(abs(audioData) > 1)
                error('All audio data must be scaled between -1 and 1')
            end
            
            % 245 is 5 ms at 48828.125 Hz sample rate
            stopSample = size(audioData,2) - 245;
            
            
            %%%%%%%%%%%%%%%%%%%%%
            % write data to TDT %
            %%%%%%%%%%%%%%%%%%%%%
            
            obj.RP.ZeroTag('audioDataL')
            obj.RP.ZeroTag('audioDataR')
            obj.RP.ZeroTag('triggerIdx')
            obj.RP.ZeroTag('triggerVals')
            obj.RP.ZeroTag('triggerDurations')
            %obj.RP.ZeroTag('stopSample')
            
            % reset buffer indexing:
            obj.RP.SoftTrg(3)
            
            status = obj.RP.WriteTagVEX('audioDataL', 0, 'F32',...
                                        audioData(1,:));
            if ~status
                error('Error writing to audioDataL buffer')
            end
            
            status = obj.RP.WriteTagVEX('audioDataR', 0, 'F32',...
                                        audioData(2,:));
            if ~status
                error('Error writing to audioDataR buffer')
            end
            
            status = obj.RP.WriteTagVEX('triggerIdx', 0, 'I32',...
                                        triggerIdx);
            if ~status
                error('Error writing to triggerIdx buffer')
            end
            
            status = obj.RP.WriteTagVEX('triggerVals', 0, 'I32',...
                                        triggerVals);
            if ~status
                error('Error writing to triggerVals buffer')
            end
            
            status = obj.RP.WriteTagVEX('triggerDurations', 0, 'F32', ...
                                        triggerDurations*1000);
            if ~status
                error('Error writing to triggerDurations buffer')
            end
            
            %status = obj.RP.SetTagVal('stopSample');
            %if ~status
            %    error('Error writing to triggerVals buffer')
            %end
            
            disp('Stimulus loaded.')
        end

        function play(obj)
            obj.RP.SoftTrg(1);
        end

        function play_blocking(obj)
            obj.RP.SoftTrg(1)
        end
        
        function currentSample = stop(obj)
            obj.RP.SoftTrg(2);
            pause(0.1);
            currentSample = obj.get_current_sample();
        end

        function currentSample = get_current_sample(obj)
            currentSample = obj.RP.GetTagVal('chan1BufIdx');
            currentSample2 = obj.RP.GetTagVal('chan2BufIdx');
            if currentSample ~= currentSample2
                error('channel buffers are misaligned (%d %d.)', currentSample, currentSample2)
            end
        end

    end
end
