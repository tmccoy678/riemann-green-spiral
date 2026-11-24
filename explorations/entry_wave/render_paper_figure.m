function render_paper_figure()
% Render a journal-style three-projection figure from the exact entry data.

here = fileparts(mfilename('fullpath'));
input = fullfile(here,'output','entry_side_coordinates.tsv');
output_dir = fullfile(here,'paper');
if ~isfolder(output_dir)
    mkdir(output_dir);
end

T = readtable(input,'FileType','text','Delimiter','\t');
sigma = T.arc ./ T.arc(end);
x = T.x;
y = T.y;
z = T.z;
eta = T.transverse;
seed_index = find(strcmp(T.source,'seed'),1);
channel_index = find(strcmp(T.source,'channel_entry'),1);
event_indices = [1, seed_index, channel_index];

blue = [0.00 0.32 0.52];
gray = [0.42 0.42 0.42];
ink = [0.08 0.08 0.08];
event_colors = [0.10 0.65 0.75; 0.18 0.55 0.32; 0.90 0.42 0.08];
event_markers = {'o','s','^'};
event_names = {'field edge','original seed','channel entry'};

fig = figure('Visible','off','Color','w','Units','inches', ...
    'Position',[0.5 0.5 7.25 2.75],'Renderer','painters');
layout = tiledlayout(fig,1,3,'TileSpacing','compact','Padding','compact');

ax1 = nexttile(layout,1);
plot(ax1,x,y,'Color',blue,'LineWidth',1.15);
hold(ax1,'on');
arrow_indices = round(linspace(80,numel(x)-120,5));
for idx = arrow_indices
    dx = x(idx+20)-x(idx);
    dy = y(idx+20)-y(idx);
    quiver(ax1,x(idx),y(idx),dx,dy,0.75,'Color',ink, ...
        'LineWidth',0.95,'MaxHeadSize',2.4,'AutoScale','off');
end
mark_events(ax1,x,y,event_indices,event_colors,event_markers);
axis(ax1,'equal');
xlabel(ax1,'$x$ (dataset units)','Interpreter','latex');
ylabel(ax1,'$y$ (dataset units)','Interpreter','latex');
title(ax1,'(a) horizontal projection','Interpreter','latex');

ax2 = nexttile(layout,2);
plot(ax2,sigma,linspace(z(1),z(end),numel(z)),'--', ...
    'Color',gray,'LineWidth',0.75);
hold(ax2,'on');
plot(ax2,sigma,z,'Color',blue,'LineWidth',1.15);
h = mark_events(ax2,sigma,z,event_indices,event_colors,event_markers);
xlabel(ax2,'normalized arclength $\sigma$','Interpreter','latex');
ylabel(ax2,'$z(\sigma)$ (dataset units)','Interpreter','latex');
title(ax2,'(b) vertical projection','Interpreter','latex');

ax3 = nexttile(layout,3);
plot(ax3,sigma,linspace(eta(1),eta(end),numel(eta)),'--', ...
    'Color',gray,'LineWidth',0.75);
hold(ax3,'on');
plot(ax3,sigma,eta,'Color',blue,'LineWidth',1.15);
mark_events(ax3,sigma,eta,event_indices,event_colors,event_markers);
xlabel(ax3,'normalized arclength $\sigma$','Interpreter','latex');
ylabel(ax3,'$\eta(\sigma)$','Interpreter','latex');
title(ax3,'(c) chord-normal projection','Interpreter','latex');

axes_list = [ax1 ax2 ax3];
for ax = axes_list
    set(ax,'FontName','Times New Roman','FontSize',8,'LineWidth',0.65, ...
        'TickDir','out','Box','off','Color','none', ...
        'XColor',ink,'YColor',ink);
    set(ax.Title,'Color',ink);
    set(ax.Title,'FontSize',8.5,'FontWeight','normal');
    set(ax.XLabel,'Color',ink);
    set(ax.YLabel,'Color',ink);
    grid(ax,'off');
end

lgd = legend(ax2,h,event_names,'Location','southoutside','Orientation','horizontal', ...
    'NumColumns',3,'Box','off','FontName','Times New Roman','FontSize',7.2);
lgd.TextColor = ink;

base = fullfile(output_dir,'Path22_Entry_Projections_Paper');
exportgraphics(fig,[base '.pdf'],'ContentType','vector','BackgroundColor','white');
exportgraphics(fig,[base '.png'],'Resolution',600,'BackgroundColor','white');
try
    exportgraphics(fig,[base '.svg'],'ContentType','vector','BackgroundColor','white');
catch
    print(fig,[base '.svg'],'-dsvg','-painters');
end
close(fig);
fprintf('PAPER_FIGURE=%s\n',base);
end

function handles = mark_events(ax,a,b,indices,colors,markers)
handles = gobjects(1,numel(indices));
for j = 1:numel(indices)
    idx = indices(j);
    handles(j) = plot(ax,a(idx),b(idx),markers{j}, ...
        'MarkerSize',5.4,'MarkerFaceColor',colors(j,:), ...
        'MarkerEdgeColor','k','LineWidth',0.55);
end
end

