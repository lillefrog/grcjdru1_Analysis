function [resultData] = basicDataFunc(dataArray)
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
    hist(arraySpikecount);
    pause
    
    % ### end main code ###
end

figure('color',[1 1 1],'position', [150,150,600,600]);
loglog(1,1);
hold on
loglog(dMean,dVar,'+b');
loglog(adMean,adVar,'og');
loglog(nMean,nVar,'+r');
loglog(anMean,anVar,'ok');
line([0.1 100],[0.1 100])
axis([0.01 1000 0.01 1000],'square');
grid on
grid minor
xlabel('Mean(N)');
ylabel('Variance(N^2)');
hold off

