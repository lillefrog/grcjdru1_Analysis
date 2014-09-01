function[fitted_vector]=gaussfit(sigma, mu, vector)
% [fitted_vector]=gaussfit(sigma, mu, vector)
% convolves array "vector" with gaussian
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% % convolves array "vector" with gaussian   
% % Author: A. Thiele                        % % 18.04.1997                            
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%   
fit_val=[(-3*sigma):1:(3*sigma)];  
y=ones(1, length(fit_val));             
y=(y*(1/(sigma*sqrt(2*pi))).*exp(-(((fit_val-mu).^2)/(2*sigma*sigma))));
fitted_vector=filter2(y,vector);
