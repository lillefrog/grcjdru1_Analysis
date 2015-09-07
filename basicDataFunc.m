function [varGain,varGainVar] = basicDataFunc(dataArray)
% function for reading the data from the grcjdru1 function.
% 
% Input:
%   array of data from grcjdru1
% 
% output
%   resultData : unknown

resultData = 1;
alignEvent = NLX_event2num('NLX_CUE_ON');
analyzeTimeRange = [50,1050]; % Range to analyze

for CELL = 1:length(dataArray)
    allTrials = dataArray{CELL}.data;
    validTrials = allTrials( ...     
        [allTrials.correctTrial]'==1 ...    % use only trials that the subject got right
        & [allTrials.hasSpikes]'==1 ...     % skip all trials without spikes after sorting
        & [allTrials.drugChangeCount]'>3);  % skip the first 3 trials after changing the drug

    % ### main code ###
    tempData = validTrials([validTrials.drug]'==1 & [validTrials.attend]'~=1);
    drugData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
    dMean(CELL) = drugData.meanSpikeNr;
    dVar(CELL) = drugData.varSpikeNr2;

    
    tempData = validTrials([validTrials.drug]'~=1 & [validTrials.attend]'~=1);
    noDrugData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
    nMean(CELL) = noDrugData.meanSpikeNr;
    nVar(CELL) = noDrugData.varSpikeNr2;
    
    tempData = validTrials([validTrials.drug]'==1 & [validTrials.attend]'==1);
    drugData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
    adMean(CELL) = drugData.meanSpikeNr;
    adVar(CELL) = drugData.varSpikeNr2;
    
    tempData = validTrials([validTrials.drug]'~=1 & [validTrials.attend]'==1);
    noDrugData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
    anMean(CELL) = noDrugData.meanSpikeNr;
    anVar(CELL) = noDrugData.varSpikeNr2;
    
    
    allData = CalculateSpikeData(validTrials,analyzeTimeRange,alignEvent);
    arraySpikecount = allData.nrSpikes;
    
    % ### end main code ###
end

%%




% currMean = dMean;
% currVar = dVar;

N = 1000;
varGVar = zeros(1,N);
for i=1:N
    currMean = dMean;
    currVar = dVar;  
    
    % remove 10% of the data and see how much it affects the data
    select = rand(1,length(currMean))<0.1;
    currMean = currMean(~select);
    currVar = currVar(~select);
    [estimates, model] = fitcurve(currMean,currVar);
    varGVar(i) = estimates;
end 
 
histfit(varGVar);
varGain = mean(varGVar);
varGainVar = std(varGVar);



figure('color',[1 1 1],'position', [150,150,600,600]);
loglog(1,1);
hold on

 [sse, FittedCurve] = model(estimates);
 loglog(currMean,currVar,'+b');
 loglog(currMean, FittedCurve, '.r');


 

modulatedMean = sort(currMean);
modulatedVar = modulatedMean + varGain .* modulatedMean.^2;
loglog(modulatedMean,modulatedVar,'-k');


% loglog(adMean,adVar,'og');
% loglog(nMean,nVar,'+r');
% loglog(anMean,anVar,'ok');
line([0.01 1000],[0.01 1000],'color',[.7 .7 .7])
axis([0.01 1000 0.01 1000],'square');
grid on
grid minor
xlabel('Mean(N)');
ylabel('Variance(N^2)');
hold off
end

function [estimates, model] = fitcurve(xdata, ydata)
start_point = 1;
model = @expfun;
estimates = fminsearch(model, start_point);
% expfun accepts curve parameters as inputs, and outputs sse,
% the sum of squares error for A*exp(-lambda*xdata)-ydata,
% and the FittedCurve. FMINSEARCH only needs sse, but we want
% to plot the FittedCurve at the end.

    function [sse, FittedCurve] = expfun(params)
        varGain = params(1);
        FittedCurve = (xdata + varGain .* xdata.^2);
        ErrorVector = (FittedCurve - ydata)/ydata;
        sse = (sum(ErrorVector.^2));
    end
end
