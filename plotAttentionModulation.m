function plotAttentionModulation(resultData)
% plot attentional modulation from an cell array of resulats from
% Analyze_Gecjdru1 

% selection criteria
pAtt = .05;
pDrug = .05;
% or 
pInteract = 0.05;

%% 
% resultData = resultData_apv{1};

% read all the stats from the data files into arrays for easy and fast handling
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
    
    driftPval(i,:) = resultData{i}.driftPval;
    driftRval(i,:) = resultData{i}.driftRval;
    
    spikeWidth(i) = resultData{i}.spkWidth.peakTrough;
end


selected = ( pValues(:,1)<pAtt ) & ( pValues(:,3)<pDrug ) & ( spikeWidth(:)>200 );
dim_ND_Mod = dim_ND_Mod(selected) ;
dim_D_Mod = dim_D_Mod(selected);    
cue_ND_Mod = cue_ND_Mod(selected);
cue_D_Mod = cue_D_Mod(selected);
stim_ND_Mod = stim_ND_Mod(selected);
stim_D_Mod = stim_D_Mod(selected) ;

%drug modulation
dim_NA_Mod  = dim_NA_Mod(selected);
dim_A_Mod   = dim_A_Mod(selected);  
cue_NA_Mod  = cue_NA_Mod(selected);
cue_A_Mod   = cue_A_Mod(selected); 
stim_NA_Mod = stim_NA_Mod(selected);
stim_A_Mod  = stim_A_Mod(selected); 

disp(['N=',num2str(sum(selected)),'/',num2str(length(selected))])

%% Plot Attentional Modulation
figure('color',[1 1 1],'position', [150,700,1500,400],'name','Attentional Modulation');
hold on

subplot(1,4,1);
plotSubfunction(stim_ND_Mod,stim_D_Mod,'STIM','No Drug','Drug');

subplot(1,4,2);
plotSubfunction(cue_ND_Mod,cue_D_Mod,'CUE','No Drug','Drug');

subplot(1,4,3);
plotSubfunction(dim_ND_Mod,dim_D_Mod,'DIM','No Drug','Drug',true);

subplot(1,4,4);
positive = ((dim_ND_Mod>0) & (dim_D_Mod>0));

NoDrug = dim_ND_Mod(positive);
Drug = dim_D_Mod(positive);

% disp('using Absolute values')
% NoDrug = abs(dim_ND_Mod);
% Drug = abs(dim_D_Mod);

ModulationIndex = (NoDrug-Drug)./(NoDrug+Drug);
hist(ModulationIndex,-0.95:0.1:0.95)
axis('square')
title('Dim Modulation');
set(gca, 'TickDir', 'out')
[p,~]=signrank(ModulationIndex);
%outtext=(['p(signrank): ', num2str(p, '%4.3f')]);
outtext=(['p(signrank): ', num2str(p, '%4.3f'),' (N=',num2str(length(ModulationIndex)),')']);
xlabel(outtext);
    
    
%% Plot Drug Modulation
% figure('color',[1 1 1],'position', [150,150,1500,400],'name','Drug Modulation');
% hold on
% 
% subplot(1,4,1);
% plotSubfunction(stim_NA_Mod,stim_A_Mod,'STIM','No Att','Att');
% 
% subplot(1,4,2);
% plotSubfunction(cue_NA_Mod,cue_A_Mod,'CUE','No Att','Att');
% 
% subplot(1,4,3);
% plotSubfunction(dim_NA_Mod,dim_A_Mod,'DIM','No Att','Att',true);
% 
% % modulation Plot
% subplot(1,4,4);
% % positive = ((dim_NA_Mod>0) & (dim_A_Mod>0));
% % NoDrug = dim_NA_Mod(positive);
% % Drug = dim_A_Mod(positive);
% 
% disp('using Absolute values')
% NoDrug = abs(dim_NA_Mod);
% Drug = abs(dim_A_Mod);
% 
% ModulationIndex = (NoDrug-Drug)./(NoDrug+Drug);
% hist(ModulationIndex,-0.9:0.1:0.9)
% axis('square')
% title('Dim Modulation');
% set(gca, 'TickDir', 'out')
% [p,~]=signrank(ModulationIndex);
% outtext=(['p(signrank): ', num2str(p, '%4.3f'),' (N=',num2str(length(ModulationIndex)),')']);
% xlabel(outtext);
    

    
function plotSubfunction(X,Y,sTitle,sXlabel,sYlabel,fit)   
% Plot 
% This does not check if the fit is significant, it just checks if there is
% a signifucant difference between the two datasets

% setup
axisLimits = [-0.2 1];
alpha = 0.05; % Alpha for confidence intervals

if nargin<6
    fit = true;  
end

% plot data
plot(X,Y,'or');

% Calculate if the two data sets are different
[pVal,~]=signrank(X,Y);

% Add fitting
if fit
    [poly,fitStruct] = polyfit(X,Y,1);   % p returns 2 coefficients fitting r = a_1 * x + a_2
    xfit = axisLimits(1):0.1:axisLimits(2);
    [yfit,DELTA] = polyconf(poly,xfit,fitStruct,'alpha',alpha);
    hold on
    plot(xfit,yfit,'-g')
    plot(xfit,yfit+DELTA,'g--');
    plot(xfit,yfit-DELTA,'g--');
    hold off
end

% nicify the figure
title(sTitle);
ylabel(sYlabel);
xlabel([sXlabel,' (p=', num2str(pVal, '%4.3f'),')']); % ,' N=',num2str(length(X))
line(axisLimits,axisLimits);
axis([axisLimits axisLimits],'square');





