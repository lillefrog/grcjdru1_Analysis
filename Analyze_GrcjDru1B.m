function [resultData] = Analyze_GrcjDru1B(spikeFileName,selectedCell)
% read the data for the GrcjDru1 experiment
%
% Input:
%   spikeFileName = Name of the sorted spike filed
%   selectedCell = the selectedCell number you want to use
%
% Output:
%   resultData = data structure contaning all kinds of nice stuff
%
% Requirements:
%   All functions in grcjdru1_Analysis folder

SHOWPLOTS = true; % set this to false if you just want the data without graphs


%% Load data from files

% Ask for the spike filename if it is not given
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
spkWidth = SpikeWidth(spikeFileName, selectedCell, false);
resultData.spkWidth = spkWidth;

% read the cortex file and align the data
[ctxDataTemp] = CTX_Read2Struct(cortexFilename);
ctxData = CleanCtxGrcjdru1Events(ctxDataTemp);
ctxData = GetCtxReactionTime(ctxData);
allData = AlignCtxAndNlxData(dividedSpikeArray,dividedEventfile,ctxData);
clear dividedSpikeArray dividedEventfile ctxData ctxDataTemp

%% select what to Analyze (this is the overall selection )

isError     = [allData.error]';  % did the program find any errors 
isCorrect   = [allData.correctTrial]'; % did the monkey compleate the task
hasSpikes    = [allData.hasSpikes]'; % is there any spikes at all
validTrials = ((isCorrect) & (~isError) & (hasSpikes) );  % Find trials that are correct, has no errors, and has spikes
validData   = allData(validTrials);

%TODO
% find the first trial with spikes in and the last trial with spikes in
% and exclude everything outside that

resultData.spikeFileName = spikeFileName;
resultData.eventFilename = eventFilename;
resultData.cortexFilename = cortexFilename;
resultData.cell = selectedCell; 
resultData.nValidTrials = sum(validTrials);
clear isError isCorrect targetDim validTrials allData selectedCell

%% select the data

%% Some possible events
% NLX_DIMMING1 
% NLX_DIMMING2
% NLX_CUE_ON
% NLX_STIM_ON
% BAR_RELEASED



%%  plot data 

if SHOWPLOTS
 
   timeArray=(-2000:2000); % time range to analyze 
    
 [~,fName,~] = fileparts(resultData.spikeFileName);
 figTitle = [fName,' cell=',num2str(resultData.cell)];
    
 selectData{1} = [validData.targetDim]'==1 & [validData.attend]'==1  ;
 selectData{2} = [validData.targetDim]'==1 & [validData.attend]'==2  ; 
 selectData{3} = [validData.targetDim]'==1 & [validData.attend]'==3  ; 
 
 selectData{4} = [validData.targetDim]'==1 & [validData.attend]'==1  ;
 selectData{5} = [validData.targetDim]'==1 & [validData.attend]'==2  ; 
 selectData{6} = [validData.targetDim]'==1 & [validData.attend]'==3  ; 
 
 selectData{7} = [validData.targetDim]'==1 & [validData.attend]'==1  ;
 selectData{8} = [validData.targetDim]'==1 & [validData.attend]'==2  ; 
 selectData{9} = [validData.targetDim]'==1 & [validData.attend]'==3  ; 
 

 % calculate the data to plot
 maxOfHist =[]; % maximum of each histogram, used to set the scale when plotting
 for i=1:3 % Align To Stimulus on
    plotData{i} = GrcjDru1Histogram(validData(selectData{i}),timeArray,NLX_event2num('NLX_STIM_ON')); %#ok<AGROW>
    maxOfHist = [maxOfHist, plotData{i}.maxHist];         %#ok<AGROW>
 end
 
  for i=4:6 % Align To Cue on
    plotData{i} = GrcjDru1Histogram(validData(selectData{i}),timeArray,NLX_event2num('NLX_CUE_ON')); %#ok<AGROW>
    maxOfHist = [maxOfHist, plotData{i}.maxHist];         %#ok<AGROW>
  end
 
  for i=7:9 % Align To Dimming
    plotData{i} = GrcjDru1Histogram(validData(selectData{i}),timeArray,NLX_event2num('NLX_DIMMING1')); %#ok<AGROW>
    maxOfHist = [maxOfHist, plotData{i}.maxHist];         %#ok<AGROW>
  end
 
 % Plot the histograms  
 % Align To Stimulus on
 histScale = max(maxOfHist);
 xLimits = [-500 1000]; % time range to plot
 figure('color',[1 1 1],'position', [100,0,1400,700]);
 subplot(3,3,1);
 title('Attend in (Align STIM)');
 PlotSpikeHistogram(plotData{1},xLimits,histScale);
 subplot(3,3,4);
 title('Attend out1');
 PlotSpikeHistogram(plotData{2},xLimits,histScale);   
 subplot(3,3,7);
 title('Attend out2');
 PlotSpikeHistogram(plotData{3},xLimits,histScale);
 
 % Align To Cue on
 xLimits = [-500 2000]; % time range to plot
  subplot(3,3,2);
 title('Attend in (Align CUE)');
 PlotSpikeHistogram(plotData{4},xLimits,histScale);
 subplot(3,3,5);
 title('Attend out1');
 PlotSpikeHistogram(plotData{5},xLimits,histScale);   
 subplot(3,3,8);
 title('Attend out2');
 PlotSpikeHistogram(plotData{6},xLimits,histScale);
 
 % Align To Dimming
  xLimits = [-2000 500]; % time range to plot
  subplot(3,3,3);
 title('Attend in (Align DIM)');
 PlotSpikeHistogram(plotData{7},xLimits,histScale);
 subplot(3,3,6);
 title('Attend out1');
 PlotSpikeHistogram(plotData{8},xLimits,histScale);   
 subplot(3,3,9);
 title('Attend out2');
 PlotSpikeHistogram(plotData{9},xLimits,histScale);

% plot title 
axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off');
text(0.4, 1,figTitle,'VerticalAlignment', 'top','Interpreter', 'none'); 

end