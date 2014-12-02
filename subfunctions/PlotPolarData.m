function [d] = PlotPolarData(data,pos,figColor)
% function for plotting a dataset in a polar plot. Is especially made for
% plotting on top of other plots. 
% It is not very generalized


radius = 0.1; % radius of the mean circle
nrDataPoints = size(data,2);
normData = (data/mean(data))*radius; % normalize data to radius

x = 0.5;
y = 0.5;


hold on

% plot circle
ang=0:0.01:2*pi; 
xp=radius*cos(ang);
yp=radius*sin(ang);
plot(x+xp,y+yp,'color',[.6 .6 .6]);
clear 'xp' 'yp'

% plot figure
for i=1:nrDataPoints
    sf = 1/sqrt(pos(i,1)^2+pos(i,2)^2); % calculate scale factor
    sf = sf*normData(i);
    xp(i)=pos(i,1)*sf;
    yp(i)=pos(i,2)*sf;
end
xvect = sum(xp);
yvect = sum(yp);
xp(i+1)=xp(1);
yp(i+1)=yp(1);
plot(x+xp,y+yp,'-o','color',figColor);
line([x x+xvect], [y y+yvect],'color',figColor,'marker','.');


d.meanVector = [xvect yvect]*(1/radius);
d.vectorLength = sqrt(xvect^2+yvect^2)*(1/radius);
d.directonality = (max(data)/min(data));



hold off

