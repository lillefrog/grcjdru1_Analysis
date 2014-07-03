function [data] = Analyze_GrcjDru1(spikeFileName,selectedCell)
% read the data for the GrcjDru1 experiment
%
% Input:
%   spikeFileName = Name of the sorted spike file
%   selectedCell = the selectedCell number you want to use
%
% Output:
%
%
% Requirements:
%   All functions in grcjdru1_Analysis folder

 if nargin<1 || isempty(spikeFileName) || ~exist(spikeFileName,'file');
    [fileName,filePath] = uigetfile('*.*','open a spike data file','MultiSelect','off'); 
    spikeFileName = fullfile(filePath,fileName);
 end
%%
 
disp('WARNING TESTING TESTING TESTING');
spikeFileName = 'E:\JonesRawData\PEN312\NLX_control\2014-06-07_07-24-14\GRCJDRU1.517 ON_GRCJDRU1.517 OFFSE17_cb.NSE'
selectedCell = 4
nargin = 2;
disp('WARNING TESTING TESTING TESTING');

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

% select what to Analyze (this is the overall selection )

isError     = [allData.error]';  % did the program find any errors 
isCorrect   = [allData.correctTrial]'; % did the monkey compleate the task
validTrials = ((isCorrect) & (~isError));  % Find trials that are correct, has no errors, and dim 1 or 2
validData   = allData(validTrials);

clear isError isCorrect targetDim validTrials allData

%% select the data

clear selectData plotData rateData
xLimits = [-1000 1000];
NLX_DIMMING1 =  25; 
analyzeTimeRange = [0,500];


alignEvent = NLX_DIMMING1;

% select the data and get the spike counts
attendInData = validData( [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.drug]'==1 );
[inDrug] = CalculateSpikeRate(attendInData,analyzeTimeRange,alignEvent);
inDrug.drug = 1; inDrug.attend = 1;

attendInData = validData( [validData.targetDim]'==1 & [validData.attend]'==1 & [validData.drug]'==0 );
[inNoDrug] = CalculateSpikeRate(attendInData,analyzeTimeRange,alignEvent);
inNoDrug.drug = 0; inNoDrug.attend = 1;

attendOut1Data = validData( [validData.targetDim]'==1 & [validData.attend]'==2 & [validData.drug]'==1 );
[out1Drug] = CalculateSpikeRate(attendOut1Data,analyzeTimeRange,alignEvent);
out1Drug.drug = 1; out1Drug.attend = 2;

attendOut1Data = validData( [validData.targetDim]'==1 & [validData.attend]'==2 & [validData.drug]'==0 );
[out1NoDrug] = CalculateSpikeRate(attendOut1Data,analyzeTimeRange,alignEvent);
out1NoDrug.drug = 0; out1NoDrug.attend = 2;

attendOut2Data = validData( [validData.targetDim]'==1 & [validData.attend]'==3 & [validData.drug]'==1 );
[out2Drug] = CalculateSpikeRate(attendOut2Data,analyzeTimeRange,alignEvent);
out2Drug.drug = 1; out2Drug.attend = 3;

attendOut2Data = validData( [validData.targetDim]'==1 & [validData.attend]'==3 & [validData.drug]'==0 );
[out2NoDrug] = CalculateSpikeRate(attendOut2Data,analyzeTimeRange,alignEvent);
out2NoDrug.drug = 0; out2NoDrug.attend = 3;


XX = {inDrug,inNoDrug,out1Drug,out1NoDrug,out2Drug,out2NoDrug};


L = length(inDataDrug);
ID = cell(2,L);
ID(1,:) = {'Drug'};
ID(2,:) = {'In1'};

L = length(inData);
I = cell(2,L);
I(1,:) = {'noDrug'};
I(2,:) = {'In1'};

L = length(out1DataDrug);
O1D = cell(2,L);
O1D(1,:) = {'Drug'};
O1D(2,:) = {'Out1'};

L = length(out1Data);
O1 = cell(2,L);
O1(1,:) = {'noDrug'};
O1(2,:) = {'Out1'};

X = [inDataDrug,inData,out1DataDrug,out1Data]';
Y = [ID,I,O1D,O1]';
Z{1} = Y(:,1)
Z{2} = Y(:,2)

anovan(X,Z);

%data = rateData;

%%  plot data

selectData{1} = [validData.targetDim]'==1 & [validData.attend]'==1  ;
selectData{2} = [validData.targetDim]'==1 & [validData.attend]'==2  ; 
selectData{3} = [validData.targetDim]'==1 & [validData.attend]'==3  ; 

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