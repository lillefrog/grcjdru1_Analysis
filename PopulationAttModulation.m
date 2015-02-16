

resultData = [resultData_apv];

for i=1:length(resultData)
    % attentioal modulation
    dim_ND_Mod(i) = resultData{i}.dim_ND_Mod;
    dim_D_Mod(i) = resultData{i}.dim_D_Mod;    
    cue_ND_Mod(i) = resultData{i}.cue_ND_Mod;
    cue_D_Mod(i) = resultData{i}.cue_D_Mod;
    stim_ND_Mod(i) = resultData{i}.stim_ND_Mod;
    stim_D_Mod(i) = resultData{i}.stim_D_Mod;
    
    %drug modulation
    dim_NA_Mod(i)  = resultData{i}.dim_NA_Mod;
    dim_A_Mod(i)   = resultData{i}.dim_A_Mod;  
    cue_NA_Mod(i)  = resultData{i}.cue_NA_Mod;
    cue_A_Mod(i)   = resultData{i}.cue_A_Mod; 
    stim_NA_Mod(i) = resultData{i}.stim_NA_Mod;
    stim_A_Mod(i)  = resultData{i}.stim_A_Mod; 
    
    pValues(i,1) =    resultData{i}.classification1.attention.pValue;
    pValues(i,2) =    resultData{i}.classification2.attention.pValue;
    pValues(i,3) =    resultData{i}.classification1.drug.pValue;
    pValues(i,4) =    resultData{i}.classification2.drug.pValue;
    pValues(i,5) =    resultData{i}.classification1.visual.pValue; 
    pValues(i,6) =    resultData{i}.classification2.interaction.pValue;
end

% select data

% hold on
% plot(-log(pValues(:,1)),-log(pValues(:,2)),'or')
% plot(-log(pValues(:,3)),-log(pValues(:,4)),'ob')
% xlabel('MyClassification');
% ylabel('AlexClassification');
% axis([0 100 0 100]);
% hold off




pAtt = 0.05;
pDrug = 0.05;
pInteract = 1.05;

selected = ( pValues(:,2)<pAtt ) & ( pValues(:,4)<pDrug ) & ( pValues(:,6)<pInteract );


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
[p,~]=signrank(stim_ND_Mod,stim_D_Mod);
xlabel(['p(signrank): ', num2str(p, '%4.3f')]);

subplot(1,4,2);
plot(cue_ND_Mod,cue_D_Mod,'or');
line([0 1],[0 1])
axis([-0.2 1 -0.2 1],'square')
title('cue');
xlabel('No Drug')
ylabel('Drug')
[p,~]=signrank(cue_ND_Mod,cue_D_Mod);
xlabel(['p(signrank): ', num2str(p, '%4.3f')]);

subplot(1,4,3);
plot(dim_ND_Mod,dim_D_Mod,'or');
line([0 1],[0 1])
axis([-0.2 1 -0.2 1],'square')
title('dim');
xlabel('No Drug')
ylabel('Drug')
[p,~]=signrank(dim_ND_Mod,dim_D_Mod);
xlabel(['NoDrug p=', num2str(p, '%4.3f'),' (N=',num2str(length(dim_ND_Mod)),')']);

% fitting
[p,S] = polyfit(dim_ND_Mod,dim_D_Mod,1);   % p returns 2 coefficients fitting r = a_1 * x + a_2

xfit = -1:0.1:1;
r = p(1) .* xfit + p(2); % compute a new vector r that has matching datapoints in x
[Y,DELTA] = polyconf(p,xfit,S,'alpha',0.05);
plot(dim_ND_Mod,dim_D_Mod,'or')
hold on
plot(xfit,r,'-g')
plot(xfit,Y+DELTA,'g--');
plot(xfit,Y-DELTA,'g--');
line([0 1],[0 1])
axis([-0.2 1 -0.2 1],'square')
hold off

subplot(1,4,4);
positive = ((dim_ND_Mod>0) & (dim_D_Mod>0));

NoDrug = dim_ND_Mod(positive);
Drug = dim_D_Mod(positive);

disp('using Absolute values')
NoDrug = abs(dim_ND_Mod);
Drug = abs(dim_D_Mod);

ModulationIndex = (NoDrug-Drug)./(NoDrug+Drug);
hist(ModulationIndex,-0.9:0.1:0.9)
axis('square')
title('Dim Modulation');
    [p,~]=signrank(ModulationIndex);
    outtext=(['p(signrank): ', num2str(p, '%4.3f')]);
    outtext=(['p(signrank): ', num2str(p, '%4.3f'),' (N=',num2str(length(ModulationIndex)),')']);
    xlabel(outtext);
    
    
%% Plot Drug Modulation
figure('color',[1 1 1],'position', [150,150,1500,400],'name','Drug Modulation');
hold on

subplot(1,4,1);
plot(stim_NA_Mod,stim_A_Mod,'or');
line([0 1],[0 1])
axis([-0.2 1 -0.2 1],'square')
title('stim');
xlabel('No Att')
ylabel('Att')
[p,~]=signrank(stim_NA_Mod,stim_A_Mod);
xlabel(['p(signrank): ', num2str(p, '%4.3f')]);

subplot(1,4,2);
plot(cue_NA_Mod,cue_A_Mod,'or');
line([0 1],[0 1])
axis([-0.2 1 -0.2 1],'square')
title('cue');
xlabel('No Att')
ylabel('Att')
[p,~]=signrank(cue_NA_Mod,cue_A_Mod);
xlabel(['p(signrank): ', num2str(p, '%4.3f')]);

subplot(1,4,3);
plot(dim_NA_Mod,dim_A_Mod,'or');
line([0 1],[0 1])
axis([-0.2 1 -0.2 1],'square')
title('dim');
xlabel('No Att')
ylabel('Att')
[p,~]=signrank(dim_NA_Mod,dim_A_Mod);
% outtext=(['p(signrank): ', num2str(p, '%4.3f'),' (N=',num2str(length(dim_NA_Mod)),')']);
xlabel(['p(signrank): ', num2str(p, '%4.3f'),' (N=',num2str(length(dim_NA_Mod)),')']);

subplot(1,4,4);
positive = ((dim_NA_Mod>0) & (dim_A_Mod>0));
%positive = ((dim_NA_Mod>0) & (dim_A_Mod>0)) | ((dim_NA_Mod>0) & (dim_A_Mod>0)) ;

NoDrug = dim_NA_Mod(positive);
Drug = dim_A_Mod(positive);

disp('using Absolute values')
NoDrug = abs(dim_NA_Mod);
Drug = abs(dim_A_Mod);

ModulationIndex = (NoDrug-Drug)./(NoDrug+Drug);
hist(ModulationIndex,-0.9:0.1:0.9)
axis('square')
title('Dim Modulation');
    [p,~]=signrank(ModulationIndex);
    outtext=(['p(signrank): ', num2str(p, '%4.3f'),' (N=',num2str(length(ModulationIndex)),')']);
    xlabel(outtext);
    