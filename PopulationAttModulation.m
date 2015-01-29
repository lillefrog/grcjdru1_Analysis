

resultData = resultData_apv;

for i=1:length(resultData)
    dim_ND_Mod(i) = resultData{i}.dim_ND_Mod;
    dim_D_Mod(i) = resultData{i}.dim_D_Mod;
    
    cue_ND_Mod(i) = resultData{i}.cue_ND_Mod;
    cue_D_Mod(i) = resultData{i}.cue_D_Mod;
   
    stim_ND_Mod(i) = resultData{i}.stim_ND_Mod;
    stim_D_Mod(i) = resultData{i}.stim_D_Mod;
    
    pValues(i,1) =    resultData{i}.classification1.attention.pValue;
    pValues(i,2) =    resultData{i}.classification2.attention.pValue;
    pValues(i,3) =    resultData{i}.classification1.drug.pValue;
    pValues(i,4) =    resultData{i}.classification2.drug.pValue;
    pValues(i,5) =    resultData{i}.classification1.visual.pValue; 
    pValues(i,6) =    resultData{i}.classification2.interaction.pValue;
end

% select data

hold on
plot(-log(pValues(:,1)),-log(pValues(:,2)),'or')
plot(-log(pValues(:,3)),-log(pValues(:,4)),'ob')
xlabel('MyClassification');
ylabel('AlexClassification');
axis([0 100 0 100]);
hold off




pAtt = 0.05;
pDrug = 0.05;
pVis = 0.05;

selected = ( pValues(:,1)<pAtt ) & ( pValues(:,2)<pDrug ) & ( pValues(:,3)<pVis );


pValues = pValues(selected,:);



%% Plot Attentional Modulation
figure('color',[1 1 1],'position', [150,150,1500,400],'name','Attentional Modulation');
hold on

subplot(1,4,1);
plot(stim_ND_Mod,stim_D_Mod,'or');
line([0 1],[0 1])
axis([-0.2 1 -0.2 1],'square')
title('stim');
xlabel('No Drug')
ylabel('Drug')

subplot(1,4,2);
plot(cue_ND_Mod,cue_D_Mod,'or');
line([0 1],[0 1])
axis([-0.2 1 -0.2 1],'square')
title('cue');

subplot(1,4,3);
plot(dim_ND_Mod,dim_D_Mod,'or');
line([0 1],[0 1])
axis([-0.2 1 -0.2 1],'square')
title('dim');

subplot(1,4,4);
positive = (dim_ND_Mod>0) & (dim_D_Mod>0);
NoDrug = dim_ND_Mod(positive);
Drug = dim_D_Mod(positive);

ModulationIndex = (NoDrug-Drug)./(NoDrug+Drug);
hist(ModulationIndex,-0.9:0.1:0.9)
axis('square')
title('Dim Modulation');
    [p,~]=signrank(ModulationIndex);
    outtext=(['p(signrank): ', num2str(p, '%4.3f')]);
    xlabel(outtext);
    
    
