
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
clear ctxDataTemp CELL_NUMBER


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


% attend in vs attend out
%   selectA =[validData.rfDim]'==1 & [validData.targetDim]'==1 & [validData.drug]'; % first dimming is in the RF and is the target
%   selectB =[validData.rfDim]'==1 & ~([validData.targetDim]'==1) & [validData.drug]'; % first dimming is in the RF and is not the target

% drug vs no drug
  selectRough = [validData.rfDim]'==1 & [validData.targetDim]'==1 ; % select what the groups have in common
  selectA = selectRough &  [validData.drug]'; % drug
  selectB = selectRough & ~[validData.drug]'; % no drug
 
DataA = validData(selectA);
DataB = validData(selectB);

alignEvent = NLX_DIMMING1;
timeArray=(-1000:2000);

% extract the spike data from Data
[plotDataA] = CalculateSpikeHistogram(DataA,timeArray,alignEvent);
[plotDataB] = CalculateSpikeHistogram(DataB,timeArray,alignEvent);

% plot the data
xLimits = [-1000 1000];
histScale = max([plotDataA.maxHist, plotDataA.maxHist]);
spikeShift = 100;
 
figure('color',[1 1 1])
subplot(2,2,1);

plotData = [plotDataA,plotDataB];
PlotSpikeHistogram(plotData,xLimits,histScale);






