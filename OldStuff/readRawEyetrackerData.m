%% read raw eyetracker data
fName = 'E:\WymanRawData\PEN253\EyeData\2015-9-4;13-39-55.txt';
eventFilename = 'E:\WymanRawData\PEN253\NLX_control\2015-09-04_15-43-29\Events.nev';
cortexFilename = 'E:\WymanRawData\PEN253\Cortex\150904\grcjdru1.69';
format = '%d8 %f %f %f %f %d %f %f %d %f %d %s';

clc

fid = fopen(fName); % Open the file 
disp('----------------------- HEADER -----------------------');
for k=1:25 % show and discard header data
    tline = fgets(fid);
    fprintf(tline);
end
disp('--------------------- HEADER END ---------------------');

rawData = textscan(fid,format,-1); % read the raw eyetracking data
fclose(fid);




%% read neuralynx

[automaticEvents,manualEvents] = NLX_ReadEventFile(eventFilename);
[manualStartEvent,manualStopEvent] = GetStartStopEvents(cortexFilename,manualEvents);
[cutEventfile] = NLX_CutEventfile(automaticEvents,manualEvents,manualStartEvent,manualStopEvent);
% Split the event file up in trials
startTrialEvent = 255; 
stopTrialEvent = 254;
[dividedEventfile] = NLX_DivideEventfile(cutEventfile,startTrialEvent,stopTrialEvent);
clear startTrialEvent stopTrialEvent cutEventfile

% Read the NSE spike file
% spikeFileName ='E:\WymanRawData\PEN253\NLX_control\2015-09-04_15-43-29\GRCJDRU1.69 ON_GRCJDRU1.69 OFFSE17_cb3.NSE';
% [spikeArray] = NLX_ReadNSEFile(spikeFileName);
% maxCellNumber = max(spikeArray(:,2));
% if nargin<2 || isempty(selectedCell); % if selectedCell is not defined
%   x = inputdlg(['Enter cell number between 1 and ',num2str(maxCellNumber),' : '],...
%              'Cell number missing', [1 50]);
%   selectedCell = str2num(x{1});     %#ok<ST2NM>
% end
% isSelectedCell = (spikeArray(:,2)==selectedCell);
% spikeArray = spikeArray(isSelectedCell,:);
% dividedSpikeArray = NLX_DivideSpikeArray(spikeArray,dividedEventfile);
clear spikeArray isSelectedCell
firstTimestamp = min([automaticEvents(1,1),manualEvents{1,1}]);
lastTimestamp = min([automaticEvents(end,1),manualEvents{end,1}]);
NlXduration = (lastTimestamp-firstTimestamp)/1000000; % duration in seconds


%% read cortex
[ctxDataTemp] = CTX_Read2Struct(cortexFilename);
ctxData = CleanCtxGrcjdru1Events(ctxDataTemp);
allData = AlignCtxAndNlxData(dividedSpikeArray,dividedEventfile,ctxData);


clear dividedSpikeArray

%% 1=code   2=TotalTime     3=DeltaTime     4=X_Gaze	5=Y_Gaze	6=Region	7=PupilWidth	8=PupilHeight	9=Quality	10=Fixation     11=Count	12=Marker
% look at eye data


rawTimeStamps  = rawData{1,2}; % timestamps
rawDuration = rawTimeStamps(end); % raw duration in seconds

fprintf('Duration of NLX file= %0.1fs, Duration of EyeFile= %0.1fs, Discrepancy= %0.1fs \n',NlXduration,rawDuration,(NlXduration-rawDuration));


eyeXposition  = rawData{1,4}; % markers
eyeYposition  = rawData{1,5}; % timestamps

markerArray  = rawData{1,12}; % markers
emptyCells = cellfun('isempty',markerArray); % find all empthy cells
markerPositions=num2cell(find(~emptyCells)); % find positions of all non empthy cells
markerArray(emptyCells) = []; % delete all the empthy cells
markers = [markerPositions,markerArray];


%% plot stuff

plot(rawTimeStamps(1:end-1),eyeYposition)
hold on
plot(rawTimeStamps([markers{:,1}]), zeros(1,length(markers)),'ok')
text(rawTimeStamps([markers{:,1}]), zeros(1,length(markers)), markers(:,2)' , 'VerticalAlignment','bottom','HorizontalAlignment','right')
xlabel('time(S)');
ylabel('eyeposition');

eventTimeStamps = ([manualEvents{:,1}]-firstTimestamp)/1000000;
plot(eventTimeStamps,zeros(1,length(eventTimeStamps)),'xr')

%resultFirst = cellfun(@(c) c(1,1), dividedEventfile);
%resultLast =  cellfun(@(c) c(end,1), dividedEventfile);
fixationStart = cellfun(@(zz) zz(find(zz(:,2)==4,1,'last'),1), dividedEventfile, 'UniformOutput', false);
emptyCells = cellfun(@isempty,fixationStart); %# find empty cells
fixationStart(emptyCells) = []; %# remove empty cells
fixationStartD = [fixationStart{:}]; % convert to array of double

fixationEnd = cellfun(@(zz) zz(find(zz(:,2)==32,1,'last'),1), dividedEventfile, 'UniformOutput', false);
emptyCells = cellfun(@isempty,fixationEnd); %# find empty cells
fixationEnd(emptyCells) = []; %# remove empty cells
fixationEndD = [fixationEnd{:}]; % convert to array of double

timeShift = 70.83;
plot((fixationStartD-firstTimestamp)/1000000+timeShift,0.5*ones(1,length(fixationStartD)),'.k');
plot((fixationEndD-firstTimestamp)/1000000+timeShift,0.5*ones(1,length(fixationEndD)),'.r');


%firstTimestamp
%automaticEvents(1,1)