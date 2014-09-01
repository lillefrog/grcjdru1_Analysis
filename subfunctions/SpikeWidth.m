function spkWidth = SpikeWidth(spikeFileName, cell, showFigure)
% This is a functon for getting the spike width from a spike file. It is a 
% modification of the BroadVsNarrowPlot function, but it is more robust and
% only works on one spike file at at a time.
%
% Input:
%  spikeFileName : The name of a sorted spike file.
%  cell : the cell number that you want to analyze.
%
% Output:
%  spkWidth.peakTrough : Delay from spike peak to minimum value
%  spkWidth.peakTroughVar : variation in delays




%% define Variables

plotIt = showFigure;


ExtractMode = 1;  % 1 all,2 numbers, 4 timestamps
ModeArray(1) = 1000;
ModeArray(2) = 6000;
SAMPLERATE = 32556; %samples/sec

%% Load data from file

    [cellNumbers, Features, Samples] = Nlx2MatSpike(spikeFileName, [0 0 1 1 1],  0, ExtractMode, ModeArray );



%% Analyze the data


 avarageDelays=zeros(1,1);


%%
orginalSamples = 1:32; % Neuralynx records 32 samples for each spike
samplesBeforeMax = 8; % Neuralynx adjusts the maximum to the 8th sample
sampleTime = 1000000/SAMPLERATE; % ysec/sample
timelineOrg= ((orginalSamples)-samplesBeforeMax) * sampleTime;  % Calculate timeline for original data
scalingFactor = 1/6; % Original Samples / New Samples % 1/6 = 6 times as many samples after interpolation
newSamples = 1:(scalingFactor):max(orginalSamples); %Array of new sample positions

timeline = spline(orginalSamples, timelineOrg, newSamples);
compactFrequencyOfDelay = zeros(length(timeline),1);

%% analyze the data for all spikes
    invert_flag=1;
    while avarageDelays<50
        SpikeArrayBig = Samples(:,1,cellNumbers(:)== cell);             % Extract all spikes for cell ==1
        if ~isempty(SpikeArrayBig) % check that it is not empty
            Amp = Features(1,cellNumbers(:)==cell) - Features(2,cellNumbers(:)==cell);    % get the full amplitude of the spike
            
            SpikeArray = squeeze(SpikeArrayBig);                        % Compress the array
            NormalizedSpikeArray = bsxfun(@rdivide,SpikeArray,Amp);     % normalize amplitude to 1
            %%%%%%%%%%%%%%%% do the spline interpolation %%%%%%%%%%%%%%%%%%%%%%%%%%

            
            spikesInterpolated = spline(orginalSamples,NormalizedSpikeArray',newSamples)'; % interpolate spikes with spline
            spikesInterpolated=spikesInterpolated*invert_flag; % invert spikes if nessary

            % calculate histogram
            DelaysOfMinimum = bsxfun(@eq,spikesInterpolated,min(spikesInterpolated(7*6:end,:)));
            DelaysOfMinimum = DelaysOfMinimum(:,sum(DelaysOfMinimum,1)==1);  %% Remove any case where there is more or less than one minimum
            FrequencyOfDelay = sum(DelaysOfMinimum,2);
            compactFrequencyOfDelay(:,cell+1) = FrequencyOfDelay(1:end) / sum(FrequencyOfDelay); % Normalize the histograms
            
            % calculate the distribution of delays
            RealDelays = bsxfun(@times,DelaysOfMinimum,(timeline'));
            CompactRealDelays = sum(RealDelays,1);
            CleanRealDelays = CompactRealDelays(CompactRealDelays ~= (timeline(end)));  % remove data that don't have a K dip
            avarageDelays = median(CleanRealDelays);
            if avarageDelays<50
                invert_flag=-1;
            end
            variationInDelays = iqr(CleanRealDelays); % inter quartile range
            spkWidth.peakTroughVar = variationInDelays;
            spkWidth.peakTrough = avarageDelays;
  
        else
            disp(['no spikes found in cell ',num2str(cell)]);
            avarageDelays = [];
            spkWidth.peakTrough = avarageDelays;
            variationInDelays = [];
            spkWidth.peakTroughVar = variationInDelays;
            break
        end
    end
    
if plotIt
    figure('color',[1 1 1],'position', [100,100,800,500]);
    plot(timeline,spikesInterpolated(:,1:30)); % ,timelineOrg,NormalizedSpikeArray(:,1),'+'
    xlabel('Time in ySec');
    ylabel('Normalized amplitude');   
end
    