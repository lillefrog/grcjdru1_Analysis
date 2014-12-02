function [outData] = Analyze_MsaccData(spikeFileName,selectedCell)

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
spkWidth = SpikeWidth(spikeFileName, selectedCell, false);
resultData.Cell=selectedCell;
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


%% NLX events

% NLX_TRIAL_START  
% NLX_RECORD_START  
% NLX_SUBJECT_START 
% NLX_STIM_ON       
% NLX_EVENT_3    
% NLX_STIM_OFF 
% NLX_SACCADE_START 
% NLX_FIXSPOT_OFF	  
% NLX_SUBJECT_END    
% NLX_RECORD_END    
% NLX_READ_DATA        
% NLX_TRIAL_END      

 
%%

AlignString = 'NLX_STIM_ON';
%AlignString = 'NLX_SACCADE_START';
%AlignString = 'NLX_TRIAL_START';
alignEvent = NLX_event2num(AlignString);


timeArray=(-1000:2000); % range to calculate data in
xLimits = [-1000 2000]; % range around align point to plot
subPlotWidth = 0.20;
subPlotHight = 0.17;
nrDirections = 9;
figureTitle = 'Aligned to Stimulus onset';

% initialize the figure
mainFig = figure('color',[1 1 1],'position', [100,100,900,900]);
maxHist =0; % initialize scale factor for histograms
plotData = cell(nrDirections,1);
posSubplot = cell(nrDirections,1);
hold on

% calculate the histograms for all directions
for i=1:nrDirections
 tempData = validData([validData.condition]'==(i-1));
 positionTarget = tempData.positionTarget;
 plotData{i} = CalculateSpikeHistogram(tempData,timeArray,alignEvent);
 maxHist = max([plotData{i}.maxHist maxHist]); % get the max amplitude of the histogram for scaling
 scaleFactor = 2.7*sqrt(positionTarget(1)^2+positionTarget(2)^2);
 posSubplot{i} = [0.5+(positionTarget/scaleFactor)-[subPlotWidth/2 subPlotHight/2] subPlotWidth subPlotHight];
 
 StimOnData = CalculateSpikeData(tempData,[0 500],NLX_event2num('NLX_STIM_ON'));
 SaccOnData = CalculateSpikeData(tempData,[0 500],NLX_event2num('NLX_SACCADE_START'));
 pos(i,:) = positionTarget;
 StimOn(i) = StimOnData.meanSpikeRate;
 SaccOn(i) = SaccOnData.meanSpikeRate;
end





% plot the histograms for all directions
for i=1:nrDirections
 subplot('position',posSubplot{i}); % Make a subplot at a definded position
 PlotSpikeHistogram(plotData{i},xLimits,maxHist); % plot the histogram to the subplot
 if i>1 % for all non RF plots
 set(gca,'YTicklabel',''); % remowe YTick lable
 set(gca,'XTicklabel',''); % remowe XTick lable
 end
end



% spiff up the main figure
figure(mainFig); % select the figur
[~, name, ext] = fileparts(resultData.cortexFilename); % get filename for title
figureTitle = [name,ext,' Cell=',num2str(resultData.Cell), '  Align to: ', AlignString];

axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off'); % make invisible axis
PlotPolarData(SaccOn,pos,[.2 .2 1]);
%PlotPolarData(StimOn,pos,[1 .2 .2]);

text(0.5, 0.97,figureTitle,'VerticalAlignment', 'top','HorizontalAlignment', 'center','Interpreter', 'none'); % print title
line([0.5 0.5],[0.49 0.51],'Color','k'); % draw the cross in the middle
line([0.49 0.51],[0.5 0.5],'Color','k'); % draw the cross in the middle


hold off

outData = 1;
 
 
 

