function pValues = plotEyeMovement(dataArray,alignEvent)
% function for analyzing eye movements. It takes the eye movements in the
% fixation period and compares it to the movement in the attention period.
% (this depends on the align event, CUE_ON is the one that should be used.
% 
% input:
% alignEvent: the event that we want to align the data to
% dataAtrray: Array of data from the analyze_GrcjDru1 function
% 
% output:
%  An array of p-values: [attetion X, drug X, attention Y, drug Y]

% set display options
SHOWPLOT = true;

% check for valid inputs
if isa(alignEvent,'double')
    alignNumber = alignEvent;
elseif isa(alignEvent,'char');
    alignNumber = CTX_event2num(alignEvent);
else
    alignNumber = 100; % align to NLX_RECORD_START if there is a error
    warning('Wrong input');
end

% initialize variables
pValues = zeros(length(dataArray),4);

% run trough all experiments
for currCell = 1:length(dataArray)
    disp(currCell)
    AllTrials = dataArray{currCell}.data;
    
    % Check if we have some Ini settings
    if dataArray{currCell}.iniValues.INIfileFound
        iniSettings = dataArray{currCell}.iniValues.Hardware;
    else
        iniSettings = [];
    end
    goodTrials = AllTrials([AllTrials.correctTrial] == 1);

    % Initialize data
    analysisTime = 20000; % The time window we want to analyze (10000 means -5000 to +5000)
    samples = analysisTime / 4; % number of samples in the analysis time, depends on the samplerate
    meanArrayX = nan(length(goodTrials),samples); % array containing all the aligned data
    meanArrayY = nan(length(goodTrials),samples); % array containing all the aligned data
    attend = zeros(length(goodTrials),1); % array keeping track of our sorting parameter (drug or attention)
    drug = zeros(length(goodTrials),1); % array keeping track of our sorting parameter (drug or attention)
    xMean = zeros(length(goodTrials),1);
    yMean = zeros(length(goodTrials),1);

    % loop trough all trials
    for trial=1:length(goodTrials) 

        % get the X and Y coordinates for the eye movement
        EOGdata = goodTrials(trial).EOGArray;    
        [EyeArrayX,EyeArrayY] = CalibrateEyeData(EOGdata,iniSettings);

        % store information about attention and drug state
        attend(trial) = goodTrials(trial).attend;
        drug(trial) = goodTrials(trial).drug+1;

        % Get the timing of the events during the trial
        currentEventArray = goodTrials(trial).eventArray; 
        startEvent = currentEventArray(:,2)==CTX_event2num('START_EYE_DATA'); % get the start time of the eye tracking
        startTime = currentEventArray(startEvent,1);
        endEvent = currentEventArray(:,2)==CTX_event2num('END_EYE_DATA'); % get the end time of the eye tracking
        endTime = currentEventArray(endEvent,1);
        alignEventPos = currentEventArray(:,2)==alignNumber; % get the time of the align event
        alignTime = currentEventArray(alignEventPos,1);
        fixOnEvent =   currentEventArray(:,2)==CTX_event2num('FIXATION_OCCURS');
        fixOnTime = currentEventArray(fixOnEvent,1);


        %TODO Find a way to look at direction and not only X and Y

        if ~(isempty(startTime) || isempty(endTime) || isempty(alignTime) || isempty(fixOnTime)) ;
            % Align the timestamps to the align event 
            timeStamps = linspace(startTime,endTime,length(EyeArrayX));

            % get the timestamps for the baseline
            msSample = (endTime - startTime) / length(EyeArrayX);
            baseline = (timeStamps>(fixOnTime(1)+50)) & (timeStamps<(fixOnTime(1)+350));

            % set the align event time to zero
            timeStamps = timeStamps - alignTime(1);
            zerothSample = find(timeStamps>0,1,'first'); % set the 0 sample in the middel
            zeroPos = (samples/2) - zerothSample;

            % calculate a baseline for each direction
            xBaseline = mean(EyeArrayX(baseline));
            yBaseline = mean(EyeArrayY(baseline));

            % normalize to baseline
            EyeArrayX = EyeArrayX - xBaseline;
            EyeArrayY = EyeArrayY - yBaseline;

            % calculate response
            zeroSample = find(timeStamps>0,1,'first');
            xMean(trial) = mean( EyeArrayX(zeroSample(1):zeroSample(1)+ round(300/msSample) ));
            yMean(trial) = mean( EyeArrayY(zeroSample(1):zeroSample(1)+ round(300/msSample) ));

            excentricity = sqrt(EyeArrayX.^2 + EyeArrayY.^2);

            meanArrayX(trial,1+zeroPos:length(excentricity)+zeroPos)  = EyeArrayX;
            meanArrayY(trial,1+zeroPos:length(excentricity)+zeroPos)  = EyeArrayY;
            
        end
    end


    xAnova = anovan(xMean,{attend,drug},'varnames',{'attend','drug'},'display','off');
    yAnova = anovan(yMean,{attend,drug},'varnames',{'attend','drug'},'display','off');
    
    pValues(currCell,:) = [xAnova' yAnova'];

    disp(['x | p attention ', num2str(xAnova(1)), ' p drug ', num2str(xAnova(2)) ]);
    disp(['y | p attention ', num2str(yAnova(1)), ' p drug ', num2str(yAnova(2)) ]);

    % Set the time axis
    

    if SHOWPLOT
        timeLine = linspace(-analysisTime/2, analysisTime/2, samples);
        % plot histogram
%         temp_mean = xMean;
%         [histY1,histX1] = hist(temp_mean(attend==1));
%         [histY2,histX2] = hist(temp_mean(attend==2));
%         [histY3,histX3] = hist(temp_mean(attend==3));
%         plot(histX1,histY1/max(histY1),'-xr');
%           hold on       
%         plot(histX2,histY2/max(histY2),'-+g');
%         plot(histX3,histY3/max(histY3),'-ob');
%         
%         pd1 = fitdist(temp_mean(attend==1),'Normal');
%         pd2 = fitdist(temp_mean(attend==2),'Normal');
%         pd3 = fitdist(temp_mean(attend==3),'Normal');
%         
%         x_values = -1:0.01:1;
%         y = pdf(pd1,x_values);
%        
%         plot(x_values,y,'r','LineWidth',2)
%         y = pdf(pd2,x_values);
%         plot(x_values,y,'g','LineWidth',2)
%         y = pdf(pd3,x_values);
%         plot(x_values,y,'b','LineWidth',2)        
%         hold off


        % plot all trials 
%         figure('color',[1 1 1],'position', [50,700,600,400],'name','All trials plot'); 
%         plot(timeLine,meanArrayX,'-b');
%         axis([-1000 3000 -5 5]);
        
        % plot eye traces and positions
        figure('color',[1 1 1],'position', [50,50,1400,500],'name','Eye movement analysis'); %,'Visible','off'
        color = {[0 0 0],[0 0 1],[1 0 0]};   

        % plot eye trace for X data
        subplot(1,3,1);
        hold on
        for i = min(attend):max(attend)
            meanArrayAtt1 = meanArrayX(attend==i,:);
            summary = nanmean(meanArrayAtt1);
            summarystd = nanstd(meanArrayAtt1);
            line(timeLine,summary,'color',color{i});
            line(timeLine,summary+summarystd,'color',color{i});
            line(timeLine,summary-summarystd,'color',color{i});    
        end
        hold off
        axis([-1000 2000 -1 1]);
        title('X axis');
        xlabel(['Time aligned to ',alignEvent],'interpreter', 'none');
        ylabel('Eccentricity drg');


        % plot eye trace for Y data
        subplot(1,3,2);
        hold on
        for i = min(attend):max(attend)
            meanArrayAtt1 = meanArrayY(attend==i,:);
            summary = nanmean(meanArrayAtt1);
            summarystd = nanstd(meanArrayAtt1);
            line(timeLine,summary,'color',color{i});
            line(timeLine,summary+summarystd,'color',color{i});
            line(timeLine,summary-summarystd,'color',color{i});
        end
        hold off

        title('Y axis');
        axis([-1000 2000 -1 1]);
        xlabel(['Time aligned to ',alignEvent],'interpreter', 'none');
        ylabel('Eccentricity drg');


        % plot average fixation points
        subplot(1,3,3);
        hold on
        axis([-10 10 -10 10],'square');
         positionRF = goodTrials(2).positionRF; 
         positionOut1 = goodTrials(2).positionOut1;
         positionOut2 = goodTrials(2).positionOut2;
         plot(positionRF(1),positionRF(2),'o','color',color{1});
         plot(positionOut1(1),positionOut1(2),'o','color',color{2});
         plot(positionOut2(1),positionOut2(2),'o','color',color{3});

        for i = min(attend):max(attend)
            meanxMean = mean(xMean(attend==i));
            meanyMean = mean(yMean(attend==i));
            plot(meanxMean,meanyMean,'+','color',color{i});  
        end

        % draw large cross marking at [0,0] for reference
        line([0 0],[-10 10],'color',[.8 .8 .8]);
        line([-10 10],[0 0],'color',[.8 .8 .8]);
        xlabel('X coordinate');
        ylabel('Y coordinate');    
    end
end




function [EyeArrayX,EyeArrayY] = CalibrateEyeData(EOGdata,settings)
% This function calculates the eye movement in degrees visual angle from
% the original voltages that cortex uses to store it. It does require that
% you have the correct settings.
%
% EOGdata: is a array of double from cotex, where uneven numbers are the X
%   values and even values are the Y values.
% settings: can come from settings = resultData.iniValues.Hardware;
%   or it can be written directly as a structure. (see the default settings
%   for structure.
%
% EyeArrayX and EyeArrayY: is evenly spaced eye positions in dregrees visual
%   angle.



% default settings
CORTEX_RESOLUTION =     [4096, 4096];
SCREEN_RESOLUTION =     [1280, 1024];
PIXELS_PER_DEGREE =     [32.63, 32.63];

% Use the loaded settings if the work
if nargin<1 
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



% calculate scaling
ScalingFactor =  SCREEN_RESOLUTION ./ (CORTEX_RESOLUTION .* PIXELS_PER_DEGREE);
        
% split data and scale it
EyeArrayX = EOGdata(1:2:end) * ScalingFactor(1);
EyeArrayY = EOGdata(2:2:end) * ScalingFactor(2);

