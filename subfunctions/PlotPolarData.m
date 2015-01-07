function [d] = PlotPolarData(data,pos,figColor,SHOWPLOTS)
% function for plotting a dataset in a polar plot. Is especially made for
% plotting on top of other plots. It also calculates different statistics
% for estimating weather there is a effect of direction.
%
% This function is not very generalized and will probably need modification
% before it can be used in any other project
%
% input
%  data = cell array, one cell for each position, containing an array of spikecounts
%  pos = array of x and y coordinates for each position
%  figColor = color for each plot f.eks. [.2 .2 .9]
%  SHOWPLOTS = If true the plots are shown else only the calculations are done
%
% output
%  .meanVector = the mean vector of spiking activity direction
%  .vectorLength = the length of the vector (could easily be calculated from vector)
%  .directonality = max(spikerate) / min(spikerate)
%  .directonSignificans = anova pValue for effect of direction


radius = 0.1; % radius of the mean circle
nrPositions = size(data,2); % positions
bootstrapIterations = 5000;

% get the mean for each position
for i=1:nrPositions
    meanData(i) = mean(data{i}); %#ok<AGROW>
end


normData = (meanData/mean(meanData))*radius; % normalize data to radius

% center of the plot
centerX = 0.5;
centerY = 0.5;


hold on

% Calculate the data for the polar plot
for i=1:nrPositions
    sf = 1/sqrt(pos(i,1)^2+pos(i,2)^2); % calculate scale factor
    sf = sf*normData(i);
    xPolar(i)=pos(i,1)*sf;
    yPolar(i)=pos(i,2)*sf;
end

% calculate and plot the average vector for the polar plot
xvect = sum(xPolar);
yvect = sum(yPolar);


% check if there is a significant effect of direction (ANOVA)
anovaData = []; % create a array for the anova
anovaPositions = [];
for i = 1:nrPositions
    anovaData = [anovaData data{i}]; %#ok<AGROW>
    tempPositions = linspace(i,i,length(data{i})) ;
    anovaPositions = [anovaPositions tempPositions]; %#ok<AGROW>
end
[anovapValue,~,~] = anovan(anovaData,{anovaPositions},'display','off');


% Bootstrap the avarage vector and directionality index
polarStats = calcPolarStats(anovaData,anovaPositions);
myF = @(bootr)calcPolarStats(bootr,anovaPositions);

bootStrapData = bootstrp(bootstrapIterations,myF,anovaData);
bootVlengthPval = sum(bootStrapData(:,1)>=polarStats(1))/bootstrapIterations; % how many of the bootstrapped values are bigger than my vLength
bootDirecPval = sum(bootStrapData(:,2)>=polarStats(2))/bootstrapIterations; % how many of the bootstrapped values are bigger than my direction index


% save data for the output
d.meanVector = [xvect yvect]*(1/radius);
d.vectorLength = sqrt(xvect^2+yvect^2)*(1/radius);
d.directonality = (max(meanData)/min(meanData));
d.directonSignificans = anovapValue;
d.bootstrapVlength = polarStats(1);
d.bootstrapDirec = polarStats(2);
d.bootVlengthPval = bootVlengthPval;
d.bootDirecPval = bootDirecPval;


if SHOWPLOTS
%     if d.vectorLength>2
%         scf=0.5; % scale factor
%     else
        scf=0.6;
%     end
    
    % plot circle
    ang=0:0.01:2*pi; 
    xCircle=radius*cos(ang)*scf;
    yCircle=radius*sin(ang)*scf;
    plot(centerX+xCircle,centerY+yCircle,'color',[.6 .6 .6]);
    
    % plot the average vector
    if (bootVlengthPval<0.05); lWidth = 2; else lWidth = 1; end
    if (bootVlengthPval<0.01); lMark = '*'; else lMark = '.'; end
    line([centerX centerX+xvect*scf], [centerY centerY+yvect*scf],'color',figColor,'marker',lMark,'linewidth',lWidth); 

    % The polar plot
    xPolar(i+1)=xPolar(1); % plot a line back to pos1
    yPolar(i+1)=yPolar(1);
    plot(centerX+xPolar*scf,centerY+yPolar*scf,'-o','color',figColor);
end

hold off






function stats = calcPolarStats(data,pos)
% calculate stats for polar data:
% vector length and directonality index
%
% it is a bit messy but because it runs within the bootstrap function it is
% extreamly time critical and this is the fastest version we have been able
% to come up with
%
% TODO calculate alpha correctly

nPositions = max(pos); % get the number of positions

%data = data/mean(data); % normalize % too slow
data = data / (sum(data)/length(data));  % normalize

% initialize
x=0;
y=0;
DD = zeros(nPositions,1);
alphaStep = (2*pi)/nPositions;

% michaels optimized C-like code for calculating the mean for each position
runningTotals = zeros(nPositions,1);
runningCounts = zeros(nPositions,1);
for i=1:length(data)
   runningTotals(pos(i)) = runningTotals(pos(i)) + data(i);
   runningCounts(pos(i)) = runningCounts(pos(i)) + 1;
end
DD(:) = runningTotals(:) ./ runningCounts(:);

% this is actually cheating we should calculate alpha from the positions!!
for i=1:nPositions
    %DD(i) = mean(data(pos==i));
    alpha = alphaStep*i;
    y = y + (DD(i) * sin(alpha));
    x = x + (DD(i) * cos(alpha));
end

vLength = sqrt(x^2+y^2);
direc = max(DD) / min(DD);

stats = [vLength,direc];

