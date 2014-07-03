function [data] = Analyze_GrcjDru1(spikeFileName,selectedCell)
% read the data for the GrcjDru1 experiment
%
% Input:
%   spikeFileName = Name of the sorted spike file
%   selectedCell = the selectedCell number you want to use
%
% output:
%
%
% Requirements:
%   All functions in grcjdru1_Analysis folder

 if nargin<1 || isempty(spikeFileName) || ~exist(spikeFileName,'file');
    [fileName,filePath] = uigetfile('*.*','open a spike data file','MultiSelect','off'); 
    spikeFileName = fullfile(filePath,fileName);
 end



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
[spikeArray] = NLX_ReadNSEFileShort(spikeFileName);
maxCellNumber = max(spikeArray(:,2));
if nargin<2 || isempty(selectedCell); % if selectedCell is not defined
  x = inputdlg(['Enter cell number between 1 and ',num2str(maxCellNumber),' : '],...
             'Cell number missing', [1 50]);
  selectedCell = str2num(x{1});    
end
isSelectedCell = (spikeArray(:,2)==selectedCell);
spikeArray = spikeArray(isSelectedCell,:);
dividedSpikeArray = NLX_DivideSpikeArray(spikeArray,dividedEventfile);
clear spikeArray isSelectedCell

% read the cortex file and align the data
[ctxDataTemp] = CTX_Read2Struct(cortexFilename);
ctxData = CleanCtxGrcjdru1Events(ctxDataTemp);
ctxData = GetCtxReactionTime(ctxData);
allData = AlignCtxAndNlxData(dividedSpikeArray,dividedEventfile,ctxData);
clear dividedSpikeArray dividedEventfile ctxData ctxDataTemp selectedCell

%% select what to Analyze (this is the overall selection )

isError     = [allData.error]';  % did the program find any errors 
isCorrect   = [allData.correctTrial]'; % did the monkey compleate the task
validTrials = ((isCorrect) & (~isError));  % Find trials that are correct, has no errors, and dim 1 or 2
validData   = allData(validTrials);

clear isError isCorrect targetDim validTrials allData

%% small plot the data

clear selectData plotData rateData
xLimits = [-1000 1000];
NLX_DIMMING1 =  25;  


alignEvent = NLX_DIMMING1;

selectData{1} = [validData.targetDim]'==1 & [validData.attend]'==1  ; 
rateData{1} = CalculateSpikeRate(validData(selectData{1}),[0,500],alignEvent);

selectData{2} = [validData.targetDim]'==1 & [validData.attend]'==2  ; 
rateData{2} = CalculateSpikeRate(validData(selectData{2}),[0,500],alignEvent);

selectData{3} = [validData.targetDim]'==1 & [validData.attend]'==3  ; 
rateData{3} = CalculateSpikeRate(validData(selectData{3}),[0,500],alignEvent);

data = rateData;

%%  plot data
figure('color',[1 1 1]);
timeArray=(-1000:2000);
maxOfHist =[];
for i=1:length(selectData)
   plotData{i} = GrcjDru1Histogram(validData(selectData{i}),timeArray,alignEvent); %#ok<AGROW>
   maxOfHist = [maxOfHist, plotData{i}.maxHist];         %#ok<AGROW>
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