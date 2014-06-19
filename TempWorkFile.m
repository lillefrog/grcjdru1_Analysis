
addpath(genpath('E:\doc\GitHub\NeuralynxAnalysis\'));
addpath(genpath('E:\doc\GitHub\grcjdru1_Analysis\'));


%% Select the file to use
% make a function that from the directory and ctx filename generates all
% the needed filenames. It should probably also generate the start and stop
% events 

eventFilename = 'E:\JonesRawData\PEN312\NLX_control\2014-06-07_07-24-14\Events.Nev';
LFP_fileName = 'E:\JonesRawData\PEN312\NLX_control\2014-06-07_07-24-14\LFP17.ncs';
spikeFileName = 'E:\JonesRawData\PEN312\NLX_control\2014-06-07_07-24-14\GRCJDRU1.517 ON_GRCJDRU1.517 OFFSE17_cb.NSE';
cortexFilename = 'E:\JonesRawData\PEN312\Cortex\140528\GRCJDRU1.517';


%% Read the files and extract the data
% this should only be very general function that don't depend much on what
% experiment is being run. More specialized function should be before or
% after.

% Read the NLX event file and cut out the part related to our experiment
[automaticEvents,manualEvents] = NLX_ReadEventFile(eventFilename);
manualStartEvent = 'grcjdru1.517 on';
manualStopEvent = 'grcjdru1.517 off';
[cutEventfile] = NLX_CutEventfile(automaticEvents,manualEvents,manualStartEvent,manualStopEvent);
clear manualStartEvent manualStopEvent manualEvents automaticEvents

% Split the event file up in trials
startTrialEvent = 255; 
stopTrialEvent = 254;
[dividedEventfile] = NLX_DivideEventfile(cutEventfile,startTrialEvent,stopTrialEvent);
clear startTrialEvent stopTrialEvent cutEventfile

% Read the NSE spike file
CELL_NUMBER = 4;
[spikeArray] = NLX_ReadNSEFileShort(spikeFileName);
isSelectedCell = (spikeArray(:,2)==CELL_NUMBER);
spikeArray = spikeArray(isSelectedCell,:);
dividedSpikeArray = NLX_DivideSpikeArray(spikeArray,dividedEventfile);
clear spikeArray isSelectedCell

% read the cortex file and align the data
[ctxDataTemp] = CTX_Read2Struct(cortexFilename);
ctxData = CleanCtxGrcjdru1Events(ctxDataTemp);
clear ctxDataTemp


allData = AlignCtxAndNlxData(dividedSpikeArray,dividedEventfile,ctxData);
clear dividedSpikeArray dividedEventfile ctxData

%[trialData] = Extract_CTX_TrialParm_Grcjdru1(cortex_event_arr);
 % some function to align the data and make sure it is aligned correctly

%% Analyze 

% select the trials we want
% go trough the trails and find the first spike skip all trials before that
% one since they are probably outside the area of interest
%   check for currupt trials
%   group the trials in drug and no drug


% isDrug    = [ctxData.drug]';
% attend    = [ctxData.attend]';
% condition = [ctxData.condition]';

isError   = [allData.error]';  % did the program find any errors 
isCorrect = [allData.correctTrial]'; % did the monkey compleate the task
%targetDim = [allData.targetDim]'; % When did the target dim 1,2 or 3
%rfDim = [allData.rfDim]'; % when did the object in RF dim?
validTrials = ((isCorrect) & (~isError));  % Find trials that are correct, has no errors, and dim 1 or 2
clear isError isCorrect targetDim

selectedData = allData(validTrials);

% Plot the data
%   get the spikes for the groups
%   make histograms
% 

%% plot

% possible alignments points
% NLX_TRIAL_START      = 255;    
% NLX_RECORD_START     =   2;    
% NLX_SUBJECT_START    =   4;    
% NLX_STIM_ON          =   8;    
% NLX_STIM_OFF         =  16;    
% NLX_SUBJECT_END      =  32;    
% NLX_RECORD_END       =  64;   
% NLX_TRIAL_END        = 254;

% NLX_TESTDIMMED       =  17;
% NLX_DISTDIMMED       =  18;
% NLX_BARRELEASED      =  19;
 NLX_CUE_ON           =  20;
% NLX_CUE_OFF          =  21;
% NLX_DIST1DIMMED      =  22;
% NLX_DIST2DIMMED      =  23;
% NLX_SACCADE_START    =  24;
NLX_DIMMING1	     =  25; 	 	
% NLX_DIMMING2	       =  26;	
% NLX_DIMMING3         =  27;
% NLX_MICRO_STIM	   =  28;
% NLX_FIXSPOT_OFF	   =  29;

 x =[selectedData.rfDim]'==1 & [selectedData.targetDim]'==1; % first dimming is in the RF and is the target
% x =[selectedData.rfDim]'==1 & ~([selectedData.targetDim]'==1); % first dimming is in the RF and is not the target

xData = selectedData(x);
alignEvent = NLX_DIMMING1;
timeArray=(-1000:2000);

% extract the spike data from xData


[plotData] = CalculateSpikeHistogram(xData,timeArray,alignEvent);




% plot the histogram

maxSpike = max(mean(plotData.histogram));
histogram = mean(plotData.histogram);
histogram = (gaussfit(30,0,histogram)/maxSpike)*100;

% plot the spike data
    % reorganize the data to line coordinates
    xPlot = plotData.xSpikes;
    n1 = nan(size(xPlot));
    x2 = [xPlot;xPlot;n1];
    A = reshape(x2,1,[]);    
    
    yPlot = plotData.ySpikes;
    n1 = nan(1,length(yPlot));
    y2 = [yPlot;yPlot+1;n1];
    B = reshape(y2,1,[]);
 
    figHistogram = figure;
    hold on
    line(A,B); % plot spikes
    plot(timeArray,histogram,'LineWidth',2,'Color',[0 0 0]);
    hold off
    
%%  histograms

k1 = 1/(sigma*sqrt(2*pi));
k2 = 2*sigma^2;
timeArray=(-1000:2000);
y = ones(size(timeArray));
sp2 = zeros(length(xData),length(timeArray));



for i=1:length(xData)
    spikes = xData(i).nlxSpikes(:,1); % get the spike times for the trial
    events = xData(i).nlxEvents; % read the neuralynx events for the trial
    alignEventPos = find(events(:,2) == alignEvent,1,'last'); % find the event to align the spikes to
    if ~isempty(alignEventPos) % skip trials that dont have a start event
        alignTime = events(alignEventPos,1); % get the time for that event
        spikes = (spikes - alignTime)/1000;
        for j=1:length(spikes)
            % this function smoothes out each spike so it counts in several
            % bins. It works like a form of interpolation
            sp1 = ((k1).*exp(-(((timeArray-spikes(j)).^2)/(k2)))); %(y*(k1).*exp(-(((timeArray-spikes(j)).^2)/(k2))));
            sp2(i,:) = sp2(i,:) + sp1;
        end
    end
end

sp3 = mean(sp2)*1000;
sp4 = gaussfit(30,0,sp3);

    figure
    line(A,B);
    hold on
plot(timeArray,sp4,'LineWidth',1,'Color',[0 0 0]);

%%

        prl= squeeze(meandata(1,h,COND,1:length(t_stim)));
        %%%%% this does the smoothing of histograms
        plotdata=gaussfit(30,0,prl');
        plot(t_stim,plotdata','color',col,'linewidth',LWidth); 
    

% x =[selectedData.rfDim]'==2 & [selectedData.targetDim]'==2; % second dimming is in the RF and is the target
% y =[selectedData.rfDim]'==2 & ~([selectedData.targetDim]'==2); % second dimming is in the RF and is not the target

% [figHandle,maxSpikeRate] = PlotRast(Group1,Group2,AlignEvent,tWin,mode);
% [figHandle,maxSpikeRate] = ScaleRast(figHandle,maxSpikeRate);




