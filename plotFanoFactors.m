function pValues = plotFanoFactors(dataArray)
% 
% input:
% dataAtrray: Array of data from the analyze_GrcjDru1 function
% 
% output:

pValues = 42;
% set display options
SHOWPLOT = true;

arrSize   = [length(dataArray{1}.classification3.attData.fanoFactorArr) , length(dataArray)];
timeRange = dataArray{1}.classification3.tineWindow; % fix spelling error
fanoAttArr = zeros(arrSize);
fanoNoAttArr = zeros(arrSize);
timeLine = ( timeRange(1):1:timeRange(2) )'; 

% run trough all experiments
for currCell = 1:length(dataArray)
    XX = dataArray{currCell}.classification3;
    fanoAtt   = XX.attData.fanoFactor;
    fanoNoAtt = XX.noAttData.fanoFactor;
    
    fanoAttArr(:,currCell)   = XX.attData.fanoFactorArr;
    fanoNoAttArr(:,currCell) = XX.noAttData.fanoFactorArr;    
end

fanoArray = sum(fanoAttArr,2);
Err = std(fanoAttArr,0,2);
PlotwithErrorbars(timeLine,fanoArray,Err,[.5 .5 .0]); % Plot fano over time

hold on
fanoArray = sum(fanoNoAttArr,2);
Err = std(fanoNoAttArr,0,2);
PlotwithErrorbars(timeLine,fanoArray,Err,[.5 .5 .9]); % Plot fano over time
hold off
xlim([-200 200]);
ylim([50 80]);
legend('Attend','NoAttend');


function PlotwithErrorbars(X,Y,Err,mainColor)
% Plots a graph with error bars. The function does not use transperency so
% it should be safe for printing.


    dimLevel = 0.65; % higher is lighter
    %mainColor = [.5 .5 .5];
    dimColor = mainColor + (1-mainColor) * dimLevel;
    mainLineWidth = 1;

% if the vectors are flipped we flip them again. A lot of other problems
% might show up here so you might check it first if there are any problems
if (size(X,1) > size(X,2))
    X = X';
    Y = Y';
    Err = Err';
end

% upper and lower border of the error patch
upperError = Y + Err;
lowerError = Y - Err;

% convert line to circumfence of patch
yPatch = [lowerError, fliplr(upperError)];
xPatch = [X, fliplr(X)];

% remove NaNs just in case
xPatch(isnan(yPatch))=[];
yPatch(isnan(yPatch))=[];

% plot the error area
zPatch = ones(size(yPatch))*(-0.01); % add a small z value to push the patch behind the rest of the plot
H.patch=patch(xPatch,yPatch,zPatch,1,'facecolor',dimColor,'edgecolor','none');

hAnnotation = get(H.patch,'Annotation');
hLegendEntry = get(hAnnotation','LegendInformation');
set(hLegendEntry,'IconDisplayStyle','off');
%plot(xPatch,yPatch,'-g');
hold on
% plot the main line
plot(X, Y, 'Color',mainColor,'LineWidth',mainLineWidth);
hold off