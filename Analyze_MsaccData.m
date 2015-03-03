function [resultData] = Analyze_MsaccData(spikeFileName,selectedCell,setup)
% Function for analyzing saccade tasks. Requires a spikefile and a selected
% cell. you can optional give it some settings in a structure.


% Ask for the spike filename if it is not given
 if nargin<1 || isempty(spikeFileName);
    [fileName,filePath] = uigetfile('*.*','open a spike data file','MultiSelect','off'); 
    spikeFileName = fullfile(filePath,fileName);
 end
 
 close all

%% settings

 % default setup
 defaultSetup.showfig = false;
 defaultSetup.saveFigPath = ''; % E:\temp
 defaultSetup.saveFileName = ''; % E:\temp\test.mat

 if nargin<3 || ~exist('setup','var')
     % if no setup is supplied use the default
    setup = defaultSetup; 
 else
     % if there is a setup use defaultSetup to fill out any missing fields
    setup = CombineStructures(setup,defaultSetup);
 end

 
 
 
 
%% Read data 

if exist(spikeFileName,'file')
    [eventFilename,cortexFilename,iniFileName] = GetGrcjdru1Filenames(spikeFileName);
else
    disp(['File not found ', spikeFileName]);
    return;
end
    

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

resultData.iniValues = ReadINI(iniFileName);

allData = GetEOGsaccadeTime(allData);
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
% NLX_SUBJECT_START % fixation starts
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

%AlignString = 'NLX_SUBJECT_START'; % fixation


AlignString = 'NLX_STIM_ON';
xLimits = [-200 1000]; % range around align point to plot

% AlignString = 'NLX_SACCADE_START';
% xLimits = [-600 600]; % range around align point to plot

% AlignString = 'NLX_TRIAL_START';
% xLimits = [-100 1000]; % range around align point to plot

alignEvent = NLX_event2num(AlignString);
timeArray=( (xLimits(1)-100) : (xLimits(2)+100) ); % range to calculate data in

subPlotWidth = 0.18;
subPlotHight = 0.15;
nrDirections = 9;

% initialize the figure

maxHist =0; % initialize scale factor for histograms
plotData = cell(nrDirections,1);
posSubplot = cell(nrDirections,1);


% calculate the histograms for all directions
for i=1:nrDirections
 tempData = validData([validData.condition]'==(i-1));
 positionTarget = tempData.positionTarget;
 plotData{i} = CalculateSpikeHistogram(tempData,timeArray,alignEvent);
 maxHist = max([plotData{i}.maxHist maxHist]); % get the max amplitude of the histogram for scaling
 scaleFactor = 2.7*sqrt(positionTarget(1)^2+positionTarget(2)^2);
 posSubplot{i} = [0.5+(positionTarget/scaleFactor)-[subPlotWidth/2 subPlotHight/2] subPlotWidth subPlotHight];
 
 %StimOnData = CalculateSpikeData(tempData,[0 500],NLX_event2num('NLX_STIM_ON'));
%  SaccOnDataA = CalculateSpikeData(tempData,[-200 0],NLX_event2num(AlignString));
%  SaccOnDataB = CalculateSpikeData(tempData,[-100 100],NLX_event2num(AlignString));
%  SaccOnDataC = CalculateSpikeData(tempData,[0 200],NLX_event2num(AlignString));

 SaccOnDataA = CalculateSpikeData(tempData,[0 200],NLX_event2num(AlignString));
 SaccOnDataB = CalculateSpikeData(tempData,[200 400],NLX_event2num(AlignString));
 SaccOnDataC = CalculateSpikeData(tempData,[400 1000],NLX_event2num(AlignString));

 pos(i,:) = positionTarget;         %#ok<AGROW>
 %StimOn{i} = StimOnData.nrSpikes;   %#ok<AGROW>
 SaccOnA{i} = SaccOnDataA.nrSpikes;   %#ok<AGROW>
 SaccOnB{i} = SaccOnDataB.nrSpikes;   %#ok<AGROW>
 SaccOnC{i} = SaccOnDataC.nrSpikes;   %#ok<AGROW>
end



if setup.showfig
    mainFig = figure('color',[1 1 1],'position', [100,100,900,900]);
    hold on
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
    figureTitle = [name,ext,' Cell=',num2str(resultData.Cell), '  Align to: ', AlignString,' SpikeWidth: ',num2str(spkWidth.peakTrough,3),'+-',num2str(spkWidth.peakTroughVar ,3)    ];
    axes('Position',[0 0 1 1],'Xlim',[0 1],'Ylim',[0 1],'Box','off','Visible','off','Units','normalized', 'clipping' , 'off'); % make invisible axis
    text(0.5, 0.97,figureTitle,'VerticalAlignment', 'top','HorizontalAlignment', 'center','Interpreter', 'none'); % print title
    line([0.5 0.5],[0.49 0.51],'Color','k'); % draw the cross in the middle
    line([0.49 0.51],[0.5 0.5],'Color','k'); % draw the cross in the middle
end

% draw polar plots
% saccOnDirec = PlotPolarData(SaccOn,pos,[.2 .2 1],setup.showfig);
saccOnDirecA = PlotPolarData(SaccOnA,pos,[1 .2 .2],setup.showfig);
saccOnDirecB = PlotPolarData(SaccOnB,pos,[.2 1 .2],setup.showfig);
saccOnDirecC = PlotPolarData(SaccOnC,pos,[.2 .2 1],setup.showfig);

if setup.showfig
    text(0.4,0.35, [' pVal: ',num2str(saccOnDirecA.bootVlengthPval)], 'Color',[1 .2 .2]);
    text(0.4,0.33, [' pVal: ',num2str(saccOnDirecB.bootVlengthPval)], 'Color',[.2 1 .2]);
    text(0.4,0.31, [' pVal: ',num2str(saccOnDirecC.bootVlengthPval)], 'Color',[.2 .2 1]);

    if exist(setup.saveFigPath,'dir') % save the figure 
        figFileName = [setup.saveFigPath,'\',name,ext,'_',num2str(resultData.Cell),'.png']; % I save it as png
        set(mainFig, 'PaperUnits', 'inches'); % measure the size in inches
        set(mainFig, 'PaperPosition', [0 0 8 8]); % plot it in the corner and set the size to 8x8 
        print(mainFig,'-dpng','-r300',figFileName); % I use print to save it
        disp(['Figur Saved as: ',figFileName]);% good to know that it worked and where it got saved
    end
    hold off
end




%% select and save the output data
resultData.saccOnDirec = saccOnDirecA;
%resultData.stimOnDirec = stimOnDirec;

% save the data to a mat file
if (length(setup.saveFileName)>2)    
    myArray{1} = resultData;
    if exist(setup.saveFileName,'file')
        % append the data
        load(setup.saveFileName); 
        myPos = length(myArray)+1;
        myArray{myPos} = resultData; %#ok<NASGU>
        save(setup.saveFileName, 'myArray');
    else
        % save the data in a new file
        myArray{1} = resultData; %#ok<NASGU>
        save(setup.saveFileName, 'myArray');
    end
end
 

%% plot figure with all eye movements

figure('color',[1 1 1],'position', [100,100,900,900]);
hold on
axis([-10 10 -10 10],'square');
 

 for direction=1:nrDirections
    tempData = validData([validData.condition]'==(direction-1));
    for trial = 1:length(tempData)
        EOGdata = tempData(trial).EOGArray;
        
        [EyeArrayX,EyeArrayY] = CalibrateEyeData(EOGdata,resultData.iniValues);
        
        currentEventArray = tempData(trial).eventArray; 
        startEvent = currentEventArray(:,2)==CTX_event2num('START_EYE_DATA'); % get the start time of the eye tracking
        startTime = currentEventArray(startEvent,1);
        endEvent = currentEventArray(:,2)==CTX_event2num('END_EYE_DATA'); % get the end time of the eye tracking
        endTime = currentEventArray(endEvent,1);
        fixOnEvent =   currentEventArray(:,2)==CTX_event2num('FIXATION_OCCURS');
        fixOnTime = currentEventArray(fixOnEvent,1);
        timeStamps = linspace(startTime,endTime,length(EyeArrayX));
        baseline = (timeStamps>(fixOnTime(1)+50)) & (timeStamps<(fixOnTime(1)+450));
        
        xBaseline = mean(EyeArrayX(baseline));
        yBaseline = mean(EyeArrayY(baseline));


        % normalize to baseline
        EyeArrayX = EyeArrayX - xBaseline;
        EyeArrayY = EyeArrayY - yBaseline;
        
        plot(EyeArrayX,EyeArrayY);   
        %disp(['direction ',num2str(direction),' trial',num2str(trial)]);
        %pause
    end
    position = tempData(1).positionTarget;
    plot(position(1),position(2),'ok','MarkerSize', 6,'LineWidth',1, 'MarkerEdgeColor','k','MarkerFaceColor',[0.9,0.9,0.0]); % ,'MarkerFaceColor',[0.5,0.5,0.5]
    rectangle('Position',[position(1)-1, position(2)-1, 2, 2]);
 end
 % draw large cross marking [0,0]
line([0 0],[-10 10],'color',[.8 .8 .8]);
line([-10 10],[0 0],'color',[.8 .8 .8]);
xlabel('X coordinate');
ylabel('Y coordinate'); 
 hold off


function [EyeArrayX,EyeArrayY] = CalibrateEyeData(EOGdata,settings)
% settings can come from settings = resultData.iniValues.Hardware;
% or it can be written directly as a structure. (see the default settings
% for structure.

% default settings
CORTEX_RESOLUTION =     [4096, 4096];
SCREEN_RESOLUTION =     [1280, 1024];
PIXELS_PER_DEGREE =     [32.63, 32.63];

% % wyman settings
% CORTEX_RESOLUTION =     [4096, 4096];
% SCREEN_RESOLUTION =     [1280, 1024];
% PIXELS_PER_DEGREE =     [49.66, 49.66];

if nargin>1
    if isfield(settings,'Hardware') % if there is a Hardware field we need the subfields.
        settings = settings.Hardware;
    end
    
    if isfield(settings,'voltageResolution');
        CORTEX_RESOLUTION = [settings.voltageResolution, settings.voltageResolution];
    end
    
    if isfield(settings,'screenResolutionX');
        SCREEN_RESOLUTION = [settings.screenResolutionX , settings.screenResolutionX];
    end
    
    if isfield(settings,'pixelsPrDegreeX');
        PIXELS_PER_DEGREE = [settings.pixelsPrDegreeX , settings.pixelsPrDegreeY];
    end
end

disp(['EOG min=',num2str(min(EOGdata)),' EOG max=',num2str(max(EOGdata))]);

% calculate scaling
ScalingFactor =  SCREEN_RESOLUTION ./ (CORTEX_RESOLUTION .* PIXELS_PER_DEGREE);
        
% split data and scale it
EyeArrayX = EOGdata(1:2:end) * ScalingFactor(1);
EyeArrayY = EOGdata(2:2:end) * ScalingFactor(2);
