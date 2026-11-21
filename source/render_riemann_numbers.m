root = fileparts(fileparts(mfilename('fullpath')));
input = fullfile(root,'data','riemann_paths.tsv');
output = fullfile(root,'artifacts','Riemann_Rolling_Numbers.gif');

data = readtable(input,'FileType','text','Delimiter','\t');
path = data(data.path_id == 22,:);
path = sortrows(path,'point_id');
n = height(path);
capacity = 220;
frames = unique(round(linspace(1,n,90)));

background = [0.008 0.018 0.045];
ink = [0.78 0.88 1.00];
cyan = [0.10 0.88 0.95];
green = [0.40 1.00 0.55];
gold = [1.00 0.74 0.20];
magenta = [1.00 0.30 0.72];

fig = figure('Visible','off','Color',background, ...
    'Position',[0 0 1280 720],'InvertHardcopy','off');
axPath = axes('Parent',fig,'Position',[0.045 0.12 0.53 0.76], ...
    'Color',background);
axText = axes('Parent',fig,'Position',[0.61 0.08 0.36 0.84], ...
    'Color',background,'Visible','off','XLim',[0 1],'YLim',[0 1]);
annotation(fig,'textbox',[0.05 0.015 0.90 0.055], ...
    'String','THE DISPLAY FORGETS; THE PATH RETURNS · EXACT MATLAB SAMPLES', ...
    'Color',[0.72 0.88 1.0],'EdgeColor','none','FontSize',12, ...
    'HorizontalAlignment','center','FontWeight','bold');

xLimits = [min(path.x)-2 max(path.x)+2];
yLimits = [min(path.y)-2 max(path.y)+2];
zLimits = [min(path.z)-0.3 max(path.z)+0.3];

for frameIndex = 1:numel(frames)
    target = frames(frameIndex);
    first = max(1,target-capacity+1);
    window = first:target;
    recent = max(1,target-11):target;

    cla(axPath);
    hold(axPath,'on');
    plot3(axPath,path.x(window),path.y(window),path.z(window), ...
        'Color',cyan,'LineWidth',3.0);
    scatter3(axPath,path.x(target),path.y(target),path.z(target), ...
        72,green,'filled','MarkerEdgeColor','white','LineWidth',0.8);

    witnessIds = [1176 1336 1376];
    witnessColors = [gold; magenta; green];
    witnessNames = ["A" "B" "C"];
    for witnessIndex = 1:numel(witnessIds)
        id = witnessIds(witnessIndex);
        if id >= first && id <= target
            scatter3(axPath,path.x(id),path.y(id),path.z(id), ...
                90,witnessColors(witnessIndex,:),'filled', ...
                'MarkerEdgeColor','white','LineWidth',0.8);
            text(axPath,path.x(id),path.y(id),path.z(id)+0.12, ...
                witnessNames(witnessIndex),'Color',witnessColors(witnessIndex,:), ...
                'FontSize',13,'FontWeight','bold','HorizontalAlignment','center');
        end
    end

    axPath.XLim = xLimits;
    axPath.YLim = yLimits;
    axPath.ZLim = zLimits;
    axPath.XColor = ink;
    axPath.YColor = ink;
    axPath.ZColor = ink;
    axPath.GridColor = [0.45 0.64 0.85];
    axPath.GridAlpha = 0.20;
    grid(axPath,'on');
    box(axPath,'on');
    view(axPath,-35,22);
    xlabel(axPath,'x'); ylabel(axPath,'y'); zlabel(axPath,'z');
    title(axPath,'PATH 22 · 220-SAMPLE ROLLING WINDOW', ...
        'Color','white','FontSize',16,'FontWeight','bold');

    if target < 1176
        state = 'APPROACHING RETURN REGION';
    elseif target < 1336
        state = 'A VISIBLE · EXCURSION FORMING';
    elseif target < 1376
        state = 'A + B VISIBLE · RETURNING';
    elseif first <= 1176
        state = 'A + B + C VISIBLE · RETURN PROVED';
    else
        state = 'RETURN PRESERVED · EARLIER WAKE CULLED';
    end

    lines = strings(0,1);
    lines(end+1) = "RIEMANN / LIVE NUMERICAL RECEIPT";
    lines(end+1) = "";
    lines(end+1) = sprintf('STATE   %s',state);
    lines(end+1) = sprintf('TARGET  %05d / %05d',target,n);
    lines(end+1) = sprintf('WINDOW  %05d : %05d  (%d)',first,target,target-first+1);
    lines(end+1) = sprintf('CURRENT  x=%9.5f',path.x(target));
    lines(end+1) = sprintf('         y=%9.5f',path.y(target));
    lines(end+1) = sprintf('         z=%9.5f',path.z(target));
    lines(end+1) = "";
    lines(end+1) = "WITNESS  A→B excursion  3.072188";
    lines(end+1) = "         A→C return     0.263924";
    lines(end+1) = "";
    lines(end+1) = "RECENT EXACT SAMPLES";
    lines(end+1) = "  id          x          y         z";
    for id = recent
        lines(end+1) = sprintf('%5d  %9.5f  %9.5f  %8.5f', ...
            path.point_id(id),path.x(id),path.y(id),path.z(id));
    end

    cla(axText);
    axText.Visible = 'off';
    text(axText,0.01,0.99,strjoin(lines,newline), ...
        'Units','normalized','VerticalAlignment','top', ...
        'Color',ink,'FontName','Menlo','FontSize',11.2, ...
        'Interpreter','none');

    drawnow;
    rgb = print(fig,'-RGBImage','-r100');
    [indexed,map] = rgb2ind(rgb,256,'nodither');
    if frameIndex == 1
        imwrite(indexed,map,output,'gif','LoopCount',Inf,'DelayTime',0.075);
    else
        imwrite(indexed,map,output,'gif','WriteMode','append','DelayTime',0.075);
    end
end

for holdFrame = 1:14
    rgb = print(fig,'-RGBImage','-r100');
    [indexed,map] = rgb2ind(rgb,256,'nodither');
    imwrite(indexed,map,output,'gif','WriteMode','append','DelayTime',0.075);
end

close(fig);
fprintf('ROLLING_NUMBERS=%s\n',output);
