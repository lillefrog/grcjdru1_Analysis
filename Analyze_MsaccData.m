function [allData] = Analyze_MsaccData(spikeFileName,selectedCell)

% Ask for the spike filename if it is not given
 if nargin<1 || isempty(spikeFileName) || ~exist(spikeFileName,'file');
    [fileName,filePath] = uigetfile('*.*','open a spike data file','MultiSelect','off'); 
    spikeFileName = fullfile(filePath,fileName);
 end

%% settings
SHOWPLOTS = true;
 
%% Read data 

[eventFilename,cortexFilename] = GetGrcjdru1Filenames(spikeFileName);

% Read the NLX event file and cut out the part related to our experiment
[automaticEvents,manualEvents] = NLX_ReadEventFile(eventFilename);
[manualStartEvent,manualStopEvent] = GetStartStopEvents(cortexFilename,manualEvents);
[cutEventfile] = NLX_CutEventfile(automaticEvents,manualEvents,manualStartEvent,manualStopEvent);
clear manualStartEvent manualStopEvent manualEvents automaticEvents

% Split the event file up in trials
startTrialEvent = 255; 
stopTrialEvent = 254;
[dividedEventfile] = NLX_DivideEventfile(cutEventfile,startTrialEvent,stopTrialEvent);
clear startTrialEvent stopTrialEvent cutEventfile


% Read the NSE spike file
[spikeArray] = NLX_ReadNSEFile(spikeFileName);
maxCellNumber = max(spikeArray(:,2));
if nargin<2 || isempty(selectedCell); % if selectedCell is not defined
  x = inputdlg(['Enter cell number between 1 and ',num2str(maxCellNumber),' : '],...
             'Cell number missing', [1 50]);
  selectedCell = str2num(x{1});     %#ok<ST2NM>
end
isSelectedCell = (spikeArray(:,2)==selectedCell);
spikeArray = spikeArray(isSelectedCell,:);
dividedSpikeArray = NLX_DivideSpikeArray(spikeArray,dividedEventfile);
clear spikeArray isSelectedCell

% Get the Spike Width
spkWidth = SpikeWidth(spikeFileName, selectedCell, SHOWPLOTS);
resultData.spkWidth = spkWidth;

% read the cortex file and align the data
[ctxDataTemp] = CTX_Read2Struct(cortexFilename);
ctxData = CleanCtxSaccp3Events(ctxDataTemp);
allData = AlignCtxAndNlxData(dividedSpikeArray,dividedEventfile,ctxData);
clear dividedSpikeArray dividedEventfile ctxData ctxDataTemp

%% select what to Analyze (this is the overall selection )

isCorrect   = [allData.correctTrial]'; % did the monkey compleate the task
hasSpikes    = [allData.hasSpikes]'; % is there any spikes at all
validTrials = ((isCorrect) & (hasSpikes) );  % Find trials that are correct, and has spikes
validData   = allData(validTrials);

%TODO
% find the first trial with spikes in and the last trial with spikes in
% and exclude everything outside that

resultData.spikeFileName = spikeFileName;
resultData.eventFilename = eventFilename;
resultData.cortexFilename = cortexFilename;
resultData.cell = selectedCell; 
resultData.nValidTrials = sum(validTrials);
clear isCorrect validTrials allData

%% Analysis 

xLimits = [-1000 1000]; % range around align point to plot

% possible align points
FIXATION_OCCURS  =  8;
START_PRE_TRIAL  = 15; 
END_PRE_TRIAL    = 16;
START_POST_TRIAL = 17; 
TURN_FIXSPOT_ON  = 35; 
TURN_FIXSPOT_OFF = 36;
REWARD         =   3;
REWARD_GIVEN   =  96;
START_EYE_DATA = 100;
END_EYE_DATA   = 101;
STIM_ON	      = 4001;
FIXSPOT_OFF	  = 4010;
SACCADE_ONSET = 5006;


%% NLX events

NLX_TRIAL_START    =  255;    
NLX_RECORD_START   =   2;    
NLX_SUBJECT_START  =   4;    
NLX_STIM_ON        =   8;   
NLX_EVENT_3        =   11;
NLX_STIM_OFF       =   16;
NLX_SACCADE_START  =   24;
NLX_FIXSPOT_OFF	   =   29;
NLX_SUBJECT_END    =   32;    
NLX_RECORD_END     =   64; 
NLX_READ_DATA      =  128;
NLX_TRIAL_END      =  254;

 
%%

alignEvent = NLX_SACCADE_START;
timeArray=(-1000:2000);

i=1;
 
 selectData = [validData.condition]'==0;
 
 xData = validData(selectData);
 plotData{i} = CalculateSpikeHistogram(validData(selectData),timeArray,alignEvent);
 
 PlotSpikeHistogram(plotData,xLimits,plotData.maxHist);
 
 
 

