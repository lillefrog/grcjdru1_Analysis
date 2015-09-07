function [varGain,varGainVar] = modulatedPoissonFit(dataArray)
% function for reading the data from the grcjdru1 function.
% 
% Input:
%   array of data from grcjdru1
% 
% output
%   varGain: the gain in variation with mean spiking range
%   varGainVar: variation in that gain when using a subset of data


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
    drugNoAtt(CELL,1) = drugData.meanSpikeNr;
    drugNoAtt(CELL,2) = drugData.varSpikeNr2;

    tempData = validTrials([validTrials.drug]'~=1 & [validTrials.attend]'~=1);
    noDrugData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
    noDrugNoAtt(CELL,1) = noDrugData.meanSpikeNr;
    noDrugNoAtt(CELL,2) = noDrugData.varSpikeNr2;
    
    tempData = validTrials([validTrials.drug]'==1 & [validTrials.attend]'==1);
    drugData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
    drugAtt(CELL,1) = drugData.meanSpikeNr;
    drugAtt(CELL,2) = drugData.varSpikeNr2;
    
    tempData = validTrials([validTrials.drug]'~=1 & [validTrials.attend]'==1);
    noDrugData = CalculateSpikeData(tempData,analyzeTimeRange,alignEvent);
    noDrugAtt(CELL,1) = noDrugData.meanSpikeNr;
    noDrugAtt(CELL,2) = noDrugData.varSpikeNr2;
    
    
    allData = CalculateSpikeData(validTrials,analyzeTimeRange,alignEvent);
    arraySpikecount = allData.nrSpikes;
    
    
    [ps, llike, pvari] = fit_Goris_model(x);
    
    
    % ### end main code ###
end

%%




[ps, llike, pvari] = fit_Goris_model(x);


sort drugNoAtt





figure('color',[1 1 1],'position', [150,150,600,600]);
loglog(1,1);
hold on



 [estimates, model] = fitcurve(currMean,currVar);
 [~, FittedCurve] = model(estimates);
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


function [Gain,GainVar] = testStability(meanData, varData)
 N = 1000;
 varGVar = zeros(1,N);
 for i=1:N
    % remove 10% of the data and see how much it affects the data
    select = rand(1,length(currMean))<0.1;
    currMean = meanData(~select);
    currVar = varData(~select);
    % fit the ruduced data set
    [estimates, ~] = fitcurve(currMean,currVar);
    % collect the estimates 
    varGVar(i) = estimates;
 end 
 
 % show the variation 
 histfit(varGVar);

 Gain = mean(varGVar);
 GainVar = std(varGVar);
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
