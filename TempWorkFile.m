
%addpath(genpath('E:\doc\GitHub\NeuralynxAnalysis\'));
%addpath(genpath('E:\doc\GitHub\grcjdru1_Analysis\'));


%% Select the file to use
% make a function that from the directory and ctx filename generates all
% the needed filenames. It should probably also generate the start and stop
% events 


spikeFileName = 'E:\JonesRawData\PEN312\NLX_control\2014-06-07_07-24-14\GRCJDRU1.517 ON_GRCJDRU1.517 OFFSE17_cb.NSE';
CELL_NUMBER = 4;

spikeFileName = 'E:\JonesRawData\PEN324\NLX_control\2014-06-30_11-12-25\GRCJDRU1.525 on_GRCJDRU1.525 offSE17_cb.NSE';
CELL_NUMBER = 2;

spikeFileName = 'E:\JonesRawData\PEN222\NLX_control\2013-11-26_18-12-29\GRCJDRU1.384 ON_GRCJDRU1.384 OFFSE17_cb.NSE';
CELL_NUMBER = 4;

[eventFilename,cortexFilename] = GetGrcjdru1Filenames(spikeFileName);

%% Read the files and extract the data
% this should only be very general function that don't depend much on what
% experiment is being run. More specialized function should be before or
% after.

% Read the NLX event file and cut out the part related to our experiment
[automaticEvents,manualEvents] = NLX_ReadEventFile(eventFilename);

[manualStartEvent,manualStopEvent] = GetStartStopEvents(cortexFilename,manualEvents);
[cutEventfile] = NLX_CutEventfile(automaticEvents,manualEvents,manualStartEvent,manualStopEvent);
clear manualStartEvent manualStopEvent manualEvents automaticEvents

% Split the NLX event file up in trials
startTrialEvent = 255; 
stopTrialEvent = 254;
[dividedEventfile] = NLX_DivideEventfile(cutEventfile,startTrialEvent,stopTrialEvent);
clear startTrialEvent stopTrialEvent cutEventfile

% Read the NSE spike file
[spikeArray] = NLX_ReadNSEFileShort(spikeFileName);
isSelectedCell = (spikeArray(:,2)==CELL_NUMBER);
spikeArray = spikeArray(isSelectedCell,:);
dividedSpikeArray = NLX_DivideSpikeArray(spikeArray,dividedEventfile);
clear spikeArray isSelectedCell

% read the cortex file and align the data
[ctxDataTemp] = CTX_Read2Struct(cortexFilename);
ctxData = CleanCtxGrcjdru1Events(ctxDataTemp);
ctxData = GetCtxReactionTime(ctxData);
allData = AlignCtxAndNlxData(dividedSpikeArray,dividedEventfile,ctxData);
clear dividedSpikeArray dividedEventfile ctxData ctxDataTemp CELL_NUMBER


%% select what to Analyze (this is the overall selection )

% select the trials we want
% go trough the trails and find the first spike skip all trials before that
% one since they are probably outside the area of interest
%   check for currupt trials
%   group the trials in drug and no drug



isError     = [allData.error]';  % did the program find any errors 
isCorrect   = [allData.correctTrial]'; % did the monkey compleate the task
validTrials = ((isCorrect) & (~isError));  % Find trials that are correct, has no errors, and dim 1 or 2
validData   = allData(validTrials);

clear isError isCorrect targetDim validTrials allData



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
%  NLX_CUE_ON           =  20;
% NLX_CUE_OFF          =  21;
% NLX_DIST1DIMMED      =  22;
% NLX_DIST2DIMMED      =  23;
% NLX_SACCADE_START    =  24;
% NLX_DIMMING1	       =  25; 	 	
% NLX_DIMMING2	       =  26;	
% NLX_DIMMING3         =  27;
% NLX_MICRO_STIM	   =  28;
% NLX_FIXSPOT_OFF	   =  29;


%% drug vs no drug first dimming
%   selectRough = [validData.rfDim]'==1 & [validData.targetDim]'==1 ; % select what the groups have in common
%   selectA = selectRough &  [validData.drug]'; % drug
%   selectB = selectRough & ~[validData.drug]'; % no drug
%   DataA = validData(selectA);
%   DataB = validData(selectB);
% 
% % extract the spike data from Data
% alignEvent = NLX_DIMMING1;
% timeArray=(-1000:2000);
% [plot_1dim_drug]   = CalculateSpikeHistogram(DataA,timeArray,alignEvent);
% [plot_1dim_nodrug] = CalculateSpikeHistogram(DataB,timeArray,alignEvent);
% 
% clear selectRough selectA selectB timeArray DataA DataA


%% drug vs no drug second dimming
%   selectRough = [validData.rfDim]'==2 & [validData.targetDim]'==2 ; % select what the groups have in common
%   selectA = selectRough &  [validData.drug]'; % drug
%   selectB = selectRough & ~[validData.drug]'; % no drug
%   DataA = validData(selectA);
%   DataB = validData(selectB);
% 
% % extract the spike data from Data
% alignEvent = NLX_DIMMING2;
% timeArray=(-1000:2000);
% [plot_2dim_drug] = CalculateSpikeHistogram(DataA,timeArray,alignEvent);
% [plot_2dim_nodrug] = CalculateSpikeHistogram(DataB,timeArray,alignEvent);
% 
% clear selectRough selectA selectB timeArray DataA DataA
  
%% small plot the data

clear selectData plotData rateData
xLimits = [-1000 1000];  % start and stop time rel. to align event
NLX_DIMMING1	       =  25;  

figure('color',[1 1 1]); 
alignEvent = NLX_DIMMING1;  % define the align event 


selectData = [validData.targetDim]'==1 & [validData.attend]'==1  ; 
plotData{1} = GrcjDru1Histogram(validData(selectData),timeArray,alignEvent);
rateData{1} = CalculateSpikeRate(validData(selectData),[0,500],alignEvent);

selectData = [validData.targetDim]'==1 & [validData.attend]'==2  ; 
plotData{2} = GrcjDru1Histogram(validData(selectData),timeArray,alignEvent);
rateData{2} = CalculateSpikeRate(validData(selectData),[0,500],alignEvent);

selectData = [validData.targetDim]'==1 & [validData.attend]'==3  ; 
plotData{3} = GrcjDru1Histogram(validData(selectData),timeArray,alignEvent);
rateData{3} = CalculateSpikeRate(validData(selectData),[0,500],alignEvent);


maxOfHist =[];
for i=1:length(plotData) % Find the total max and use that to scale raster plots
   maxOfHist = [maxOfHist, plotData{i}.maxHist];         %#ok<AGROW>
   disp(rateData{i}.meanSpikeRate);
end
histScale = max(maxOfHist);

subplot(3,1,1);
title('Attend in');

PlotSpikeHistogram(plotData{1},xLimits,histScale);
subplot(3,1,2);
title('Attend out1');
PlotSpikeHistogram(plotData{2},xLimits,histScale);   
subplot(3,1,3);
title('Attend out2');
PlotSpikeHistogram(plotData{3},xLimits,histScale);


%% alex plot
% xLimits = [-1000 1000];
% timeArray=(-1000:2000);
%  NLX_STIM_ON           =   8;    
%  NLX_CUE_ON            =  20;
%  NLX_DIMMING1	       =  25; 	 	
%  %NLX_DIMMING2	       =  26;
% 
% 
% pos=[0.01, 0.01, 0.85, 0.85];
% figName = 'Alex Plot';
% figure('color',[1 1 1],...
%         'Units', 'Normalized',...
%         'Position',pos,...
%         'NumberTitle', 'off',...
%         'PaperUnits', 'centimeters',...
%         'PaperType', 'A4',...
%         'PaperOrientation', 'landscape',...
%         'Name', figName,...
%         'PaperPosition', [0.0 0.0 29.305 20.65]...
%         );
% 
% %%% align to stim onset    
% alignEvent = NLX_STIM_ON;
% 
% selectData = [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.stimDirection]'==1 ; 
% plotData{1} = GrcjDru1Histogram(validData(selectData),timeArray,alignEvent);
% 
% selectData = [validData.targetDim]'==1 & [validData.attend]'==2 & [validData.stimDirection]'==1 ; 
% plotData{2} = GrcjDru1Histogram(validData(selectData),timeArray,alignEvent);
% 
% selectData = [validData.targetDim]'==1 & [validData.attend]'==3 & [validData.stimDirection]'==1 ; 
% plotData{3} = GrcjDru1Histogram(validData(selectData),timeArray,alignEvent);
% 
% selectData = [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.stimDirection]'==-1 ; 
% plotData{4} = GrcjDru1Histogram(validData(selectData),timeArray,alignEvent);
% 
% selectData = [validData.targetDim]'==1 & [validData.attend]'==2 & [validData.stimDirection]'==-1 ; 
% plotData{5} = GrcjDru1Histogram(validData(selectData),timeArray,alignEvent);
% 
% selectData = [validData.targetDim]'==1 & [validData.attend]'==3 & [validData.stimDirection]'==-1 ; 
% plotData{6} = GrcjDru1Histogram(validData(selectData),timeArray,alignEvent);
% 
% %%% align to cue on
% alignEvent = NLX_CUE_ON ;
% 
% selectData = [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.stimDirection]'==1 ; 
% plotData{7} = GrcjDru1Histogram(validData(selectData),timeArray,alignEvent);
% 
% selectData = [validData.targetDim]'==1 & [validData.attend]'==2 & [validData.stimDirection]'==1 ; 
% plotData{8} = GrcjDru1Histogram(validData(selectData),timeArray,alignEvent);
% 
% selectData = [validData.targetDim]'==1 & [validData.attend]'==3 & [validData.stimDirection]'==1 ; 
% plotData{9} = GrcjDru1Histogram(validData(selectData),timeArray,alignEvent);
% 
% selectData = [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.stimDirection]'==-1 ; 
% plotData{10} = GrcjDru1Histogram(validData(selectData),timeArray,alignEvent);
% 
% selectData = [validData.targetDim]'==1 & [validData.attend]'==2 & [validData.stimDirection]'==-1 ; 
% plotData{11} = GrcjDru1Histogram(validData(selectData),timeArray,alignEvent);
% 
% selectData = [validData.targetDim]'==1 & [validData.attend]'==3 & [validData.stimDirection]'==-1 ; 
% plotData{12} = GrcjDru1Histogram(validData(selectData),timeArray,alignEvent);
% 
% %%% Align to first dimming
% alignEvent = NLX_DIMMING1;
% 
% selectData = [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.stimDirection]'==1 ; 
% plotData{13} = GrcjDru1Histogram(validData(selectData),timeArray,alignEvent);
% 
% selectData = [validData.targetDim]'==1 & [validData.attend]'==2 & [validData.stimDirection]'==1 ; 
% plotData{14} = GrcjDru1Histogram(validData(selectData),timeArray,alignEvent);
% 
% selectData = [validData.targetDim]'==1 & [validData.attend]'==3 & [validData.stimDirection]'==1 ; 
% plotData{15} = GrcjDru1Histogram(validData(selectData),timeArray,alignEvent);
% 
% selectData = [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.stimDirection]'==-1 ; 
% plotData{16} = GrcjDru1Histogram(validData(selectData),timeArray,alignEvent);
% 
% selectData = [validData.targetDim]'==1 & [validData.attend]'==2 & [validData.stimDirection]'==-1 ; 
% plotData{17} = GrcjDru1Histogram(validData(selectData),timeArray,alignEvent);
% 
% selectData = [validData.targetDim]'==1 & [validData.attend]'==3 & [validData.stimDirection]'==-1 ; 
% plotData{18} = GrcjDru1Histogram(validData(selectData),timeArray,alignEvent);
% 
% maxOfHist =[];
% for i=1:18
%    maxOfHist = [maxOfHist, plotData{i}.maxHist];         %#ok<AGROW>
% end
% histScale = max(maxOfHist);
% 
% for i=1:18
%     if i<7
%         subplot(3,8,i);
%     elseif i<13
%         subplot(3,8,i+2);
%     elseif i<19;
%         subplot(3,8,i+4);
%     end
%     PlotSpikeHistogram(plotData{i},xLimits,histScale);
% end


bar([1,2,3],'bar_color',)


%% stuff

spikeFileName ='E:\JonesRawData\PEN262\NLX_control\2014-02-26_12-34-01\GRCJDRU1.438 ON_GRCJDRU1.438 OFFSE17_cb3.NSE';
selectedCell =3;


for i=1:length(validData)-1
    x(i) = length(validData(i).nlxSpikes);
end

x=x'


nTrials = 50; % number of trials
nSpikes = 1000; % number of spikes
SS = 5000; % sum of squares of spikecount

iterations = 10000;
h = hist(ceil(rand(nSpikes,iterations)*nTrials),1:nTrials);
SSS = sum(h.*h); % sum of squares Simulated
pvalue = (sum(SSS<=SS)+1)/(iterations+1);

