function [outData,markers,headerText] = readRawEyeData(fName)
% function for reading raw data from the eyetracker,

% TODO
%
% this functio should only return the most important variables, probably
% time, eyeX, eyeY, pupilHeight, pupilWidth (markers)
%
%

%fName = 'E:\WymanRawData\PEN256\EyeData\2015-9-10;12-18-53.txt';
%% 1=code   2=TotalTime     3=DeltaTime     4=X_Gaze	5=Y_Gaze	6=Region	7=PupilWidth	8=PupilHeight	9=Quality	10=Fixation     11=Count	12=Marker
format = '%d8 %f %f %f %f %d %f %f %d %f %d %s'; % data file format
lengthHeader = 30; % the header seems to vary in size, so this will cut a bit of the data for safety


fid = fopen(fName); % Open the file 

if fid~=-1
    cleanObject = onCleanup(@()fclose(fid));

    headerText = cell(lengthHeader,1);
    for k=1:lengthHeader % show and discard header data
        textLine = fgets(fid);
        headerText{k,1} = textLine;
    end

    rawData = textscan(fid,format,-1); % read the raw eyetracking data
    clear cleanObject % this automatically closes the data file
else
    disp(['file not found in readRawEyeData:', fName]);
end
    



%% read markers 
% there are only a very few markers so we clean out all the empty lines to
% make it faster to use.

markerArray  = rawData{1,12}; % markers
emptyCells = cellfun('isempty',markerArray); % find all empty cells
markerPositions=num2cell(find(~emptyCells)); % find positions of all non empty cells
markerArray(emptyCells) = []; % delete all the empty cells
markers = [markerPositions,markerArray];

% return only the needed data, this might change with the format of the raw
% file, but hopefully it should stay constant
outData = {rawData{1,2},rawData{1,4},rawData{1,5},rawData{1,7},rawData{1,8}};