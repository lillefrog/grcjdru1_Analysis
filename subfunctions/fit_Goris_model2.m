function [gain, llike, pvari] = fit_Goris_model2(x)

% x: input matrix with conditions(rows) and trials(columns); negative values
%   are used to indicate different number of trials per conditions
% ps: parameter of gain of the gamma distribution. A single parameter is 
%   inferred and assumed constant for all conditions
% llike: total negative log-likelihood for the selected parameter value
% pvari: percentage of variance (normalized to one) explained by the gain fluctuations for
%   each condition. There are two columns, the first follows eq. 3 of Goris
%   et al 2014. The second normalizes by the real variance.

% initailize variables
 numberConditions = size(x,1);                       % number of conditions?
 meanOfCondition = zeros(numberConditions,1);        % means for each condition
 varianceOfCondition = zeros(numberConditions,1);    % variance for each condition
 nTrialsCond = zeros(numberConditions,1);            % number of trials for each condition
 allSpikeCounts = [];

 
for cond = 1:numberConditions
  spikeNumbers = x(cond,x(cond,:)>-1);              % get spikenumbers for all trials with positive number of trials
  meanOfCondition(cond) = mean(spikeNumbers);       % Get mean spike number
  varianceOfCondition(cond) = var(spikeNumbers);    % Get variance of spike numbers
  allSpikeCounts = [allSpikeCounts spikeNumbers];   % combine all spike counts across conditions
  nTrialsCond(cond)=length(spikeNumbers);           % store number of spike counts 
end
cumulativeSums = [0 cumsum(nTrialsCond)'];          % make an array of cumulative sums


pvari = zeros(length(meanOfCondition),2); % initialize variable

[gain, llike] = nbinfit2(allSpikeCounts,meanOfCondition,varianceOfCondition,cumulativeSums); % fitting of the negative binomial.
pvari(:,1) = (gain*meanOfCondition.^2)./(meanOfCondition+gain*meanOfCondition.^2); 
pvari(:,2) = (gain*meanOfCondition.^2)./(varianceOfCondition);


function [parmhat, llike] = nbinfit2(ys,mus,s2s,nts)
% function for fitting data to goris model 
%
% ys: vector with all trials from all conditions
% mus: mean for each condition
% s2s: variances for each condition
% nts: cumulative number of trials per condition
% parmhat: estimated gain parameter
% llike: negative log-likelihood for the estimated parameter

Nc = length(mus); % number of conditions
options = statset('nbinfit'); % default values of the parameters

% check that all trials are stored as double
if ~isfloat(ys) 
    ys = double(ys);
end


% Use Method of Moments estimates as starting point for MLEs.
rhats = zeros(Nc,1); % initialize
for i = 1:Nc 
    xbar = mus(i); % mean for current condition
    s2 = s2s(i); % variance for current condition
    rhats(i) = (xbar.*xbar) ./ (s2-xbar); % 
end
rhat = nanmean(rhats);

if rhat < 0
    parmhat = cast([NaN],class(ys));
    llike = cast([NaN],class(ys));
    warning('stats:nbinfit:MeanExceedsVariance',...
        'The sample mean exceeds the sample variance -- use POISSFIT instead.');
    return
end

% Parameterizing with mu=r(1-p)/p makes this a 1-D search for rhat.
[rhat,nll,err,output] = ...
    fminsearch(@negloglike, rhat, options, nts, ys, mus, options.TolBnd);
if (err == 0)
    % fminsearch may print its own output text; in any case give something
    % more statistical here, controllable via warning IDs.
    if output.funcCount >= options.MaxFunEvals
        wmsg = 'Maximum likelihood estimation did not converge.  Function evaluation limit exceeded.';
    else
        wmsg = 'Maximum likelihood estimation did not converge.  Iteration limit exceeded.';
    end
    if rhat > 100 % shape became very large
       wmsg = sprintf('%s\n%s', wmsg, ...
                      'The Poisson distribution might provide a better fit.');
    end
    warning('stats:nbinfit:IterOrEvalLimit',wmsg);
elseif (err < 0)
    error('stats:nbinfit:NoSolution', ...
          'Unable to reach a maximum likelihood solution.');
end
parmhat = [1/rhat];
llike = nll;


%-------------------------------------------------------------------------

function nll = negloglike(r, nts, y, mus, tolBnd)
% Objective function for fminsearch().  Returns the negative of the
% (profile) log-likelihood for the negative binomial, evaluated at
% r.  From the likelihood equations, phat = rhat/(xbar+rhat), and so the
% 2-D search for [rhat phat] reduces to a 1-D search for rhat -- also
% equivalent to reparametrizing in terms of mu=r(1-p)/p, where muhat=xbar
% can be found explicitly.

% Restrict r to the open interval (0, Inf).
Nc = length(mus); % number of conditions
nlls = zeros(Nc,1); % initialize variable
if r < tolBnd % why do we check Parameter bound tolerance here, don't the fuction do that already
    nll = Inf; 
else
    for i=1:Nc
      x = y(1+nts(i):nts(i+1));  % get the currnt trial spike counts
      sumx = sum(x); % sum of spike counts
      n = length(x); % number of spike counts
      xbar = mean(x); % mean of spike counts
      nlls(i) = -sum(gammaln(r+x)) + n*gammaln(r) - n*r*log(r/(xbar+r)) - sumx*log(xbar/(xbar+r));
    end
    nll = sum(nlls);
end