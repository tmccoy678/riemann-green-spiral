seeds = [1019 1231 1427 1601 1789 1999 2311 319 571];
seconds = [227.908996709 227.581206250 228.098118583 ...
    227.767398292 227.816345333 228.220925917 181.645577916 ...
    177.069158000 177.459749208];
bytes = [4291805991 4291498148 4291313890 4290817928 4290623388 ...
    4291051077 4291174511 4291511684 4291539148];
choices = 1728000 * ones(size(seeds));
status = [repmat("RAW RECOVERED",1,7) "EXACT RERUN" "EXACT RERUN"];

root = fileparts(fileparts(mfilename('fullpath')));
output = fullfile(root,'artifacts','Studio_Nine_Run_Scale.png');
colors = turbo(numel(seeds));
background = [0.01 0.02 0.05];
ink = [0.82 0.90 1.00];

fig = figure('Visible','off','Color',background, ...
    'Position',[0 0 1600 900],'InvertHardcopy','off');
layout = tiledlayout(fig,1,2,'Padding','compact','TileSpacing','compact');
title(layout,'HEARTH / NINE FULL RUST SCREENS', ...
    'Color','white','FontSize',24,'FontWeight','bold');
subtitle(layout, ...
    '15,552,000 choices  •  38.621 GB raw audit  •  31.726 aggregate engine-minutes', ...
    'Color',[0.65 0.82 1.00],'FontSize',14);

ax1 = nexttile(layout,1);
hold(ax1,'on');
ax1.Color = background;
for k = 1:numel(seeds)
    turn = seconds(k) / max(seconds);
    theta = linspace(pi/2,pi/2 + 2*pi*turn,720);
    radius = 0.72 + 0.30*k + 0.055*(theta-theta(1))/(2*pi) ...
        + 0.025*sin(18*theta+k);
    plot(ax1,radius.*cos(theta),radius.*sin(theta), ...
        'Color',colors(k,:),'LineWidth',3.2);
    scatter(ax1,radius(end)*cos(theta(end)),radius(end)*sin(theta(end)), ...
        48,colors(k,:),'filled');
    text(ax1,radius(1)*cos(theta(1)),radius(1)*sin(theta(1))+0.07, ...
        sprintf('%d',seeds(k)),'Color',colors(k,:), ...
        'FontSize',9,'HorizontalAlignment','center','FontWeight','bold');
end
text(ax1,0,0.12,'HEARTH','Color','white','FontSize',21, ...
    'FontWeight','bold','HorizontalAlignment','center');
text(ax1,0,-0.12,'9 × 1,728,000','Color',ink,'FontSize',12, ...
    'HorizontalAlignment','center');
text(ax1,0,-0.30,'adaptive choices','Color',[0.52 0.72 0.95], ...
    'FontSize',10,'HorizontalAlignment','center');
axis(ax1,'equal');
axis(ax1,'off');
title(ax1,'Each trace is one complete screen', ...
    'Color','white','FontSize',15,'FontWeight','bold');

ax2 = nexttile(layout,2);
ax2.Color = background;
bars = barh(ax2,bytes/1e9,0.70,'FaceColor','flat','EdgeColor','none');
bars.CData = colors;
ax2.YDir = 'reverse';
ax2.YTick = 1:numel(seeds);
labels = strings(size(seeds));
for k = 1:numel(seeds)
    labels(k) = sprintf('seed %d  ·  %s',seeds(k),status(k));
end
ax2.YTickLabel = labels;
ax2.XLim = [0 5.25];
ax2.XColor = ink;
ax2.YColor = ink;
ax2.GridColor = [0.45 0.60 0.80];
ax2.GridAlpha = 0.18;
ax2.XGrid = 'on';
ax2.FontSize = 10;
xlabel(ax2,'raw audit gigabytes','Color',ink);
title(ax2,'Every run produced about 4.29 GB', ...
    'Color','white','FontSize',15,'FontWeight','bold');
for k = 1:numel(seeds)
    text(ax2,bytes(k)/1e9+0.04,k, ...
        sprintf('%.3f GB  ·  %.1f s',bytes(k)/1e9,seconds(k)), ...
        'Color',colors(k,:),'FontSize',9,'VerticalAlignment','middle');
end

annotation(fig,'textbox',[0.08 0.015 0.84 0.055], ...
    'String',['Music for 18 Musicians was playing  •  MATLAB revealed ' ...
    'Riemann in 21.420 seconds  •  seeds 319 + 571 reproduced byte for byte'], ...
    'Color',[0.75 0.88 1.0],'EdgeColor','none','FontSize',12, ...
    'HorizontalAlignment','center','FontWeight','bold');

exportgraphics(fig,output,'Resolution',180,'BackgroundColor',background);
close(fig);
fprintf('STUDIO_SCALE=%s\n',output);
