function [rVal,pVal] = calculateDrift(resultData)
% this function checks if there is a correlation between trail number and
% spike rate. 
% if showFigure is set to true it will plot a figure with the trials split
% up in

showFigure = false;

% rawData = resultData.data;

 rawData = resultData;

% initialize 
attNoDrug = [];
attDrug = [];
noAttNoDrug = [];
noAttDrug = [];
attNoDrugT = [];
attDrugT = [];
noAttNoDrugT = [];
noAttDrugT = [];

for i=1:length(rawData)
    % duration1 = rawData(i).trialDuration;
    duration2 = rawData(i).nlxTrialDuration;
    nSpikes = length(rawData(i).nlxSpikes);
    spikeRate = (nSpikes/duration2)*1000; % spikes pr sec?
    drug = rawData(i).drug;
    attend = rawData(i).attend;
    if nSpikes>0 % check that we only use trials that actually have spikes
        if drug
            if attend==1
                attDrug = [attDrug, spikeRate];
                attDrugT = [attDrugT, i];
            else
                noAttDrug = [noAttDrug, spikeRate];
                noAttDrugT = [noAttDrugT, i];
            end
        else
            if attend==1
                attNoDrug = [attNoDrug, spikeRate];
                attNoDrugT = [attNoDrugT, i];
            else
                noAttNoDrug = [noAttNoDrug, spikeRate];
                noAttNoDrugT = [noAttNoDrugT, i];
            end
        end
    end
end

allTrials = [attDrug,noAttDrug,attNoDrug,noAttNoDrug];
allTrialsT = [attDrugT,noAttDrugT,attNoDrugT,noAttNoDrugT];

% calculate correlations 
[R,P]= corrcoef(allTrials,allTrialsT); % all trials
rVal(1) = R(2,1);
pVal(1) = P(2,1);
[R,P]= corrcoef(attDrug,attDrugT); % Att Drug
rVal(2) = R(2,1);
pVal(2) = P(2,1);
[R,P]= corrcoef(noAttDrug,noAttDrugT); % No Att Drug
rVal(3) = R(2,1);
pVal(3) = P(2,1);
[R,P]= corrcoef(attNoDrug,attNoDrugT); % Att No Drug
rVal(4) = R(2,1);
pVal(4) = P(2,1);
[R,P]= corrcoef(noAttNoDrug,noAttNoDrugT); % No Att No Drug
rVal(5) = R(2,1);
pVal(5) = P(2,1);

%% plot figure
if showFigure
    % initialize the figure
    xLimits = [0 length(rawData)];
    yLimits = [0 max(allTrials)];
    figName = ['Drift Analysis','  r=',num2str(rVal(1),'%4.2f'),' p=',num2str(pVal(1),'%4.3f') ];
    figure('color',[1 1 1],'position', [150,150,1400,350],'name',figName);
    hold on
    
    % plot Attention with Drug
    subplot(1,4,1)
    plot(attDrugT,attDrug,'or');
    axis([xLimits yLimits]);
    title('Att Drug');
    xlabel(['r=',num2str(rVal(2),'%4.2f'),' p=',num2str(pVal(2),'%4.3f')]);
    
    % plot No Attention with Drug
    subplot(1,4,2)
    plot(noAttDrugT,noAttDrug,'og');
    axis([xLimits yLimits]);
    title('NoAtt Drug');
    xlabel(['r=',num2str(rVal(3),'%4.2f'),' p=',num2str(pVal(3),'%4.3f')]);

    % plot Attention with No Drug
    subplot(1,4,3)
    plot(attNoDrugT,attNoDrug,'ob');
    axis([xLimits yLimits]);
    title('Att NoDrug');
    xlabel(['r=',num2str(rVal(4),'%4.2f'),' p=',num2str(pVal(4),'%4.3f')]);

    % plot No Attention with No Drug
    subplot(1,4,4)
    plot(noAttNoDrugT,noAttNoDrug,'ok');
    axis([xLimits yLimits]);
    title('NoAtt NoDrug');
    xlabel(['r=',num2str(rVal(5),'%4.2f'),' p=',num2str(pVal(5),'%4.3f')]);
    
    hold off
end