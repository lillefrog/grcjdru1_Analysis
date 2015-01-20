


for i=1:length(resultData)
    dim_ND_Mod(i) = resultData{i}.dim_ND_Mod;
    dim_D_Mod(i) = resultData{i}.dim_D_Mod;
    
    cue_ND_Mod(i) = resultData{i}.cue_ND_Mod;
    cue_D_Mod(i) = resultData{i}.cue_D_Mod;
   
    stim_ND_Mod(i) = resultData{i}.stim_ND_Mod;
    stim_D_Mod(i) = resultData{i}.stim_D_Mod;
end

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
