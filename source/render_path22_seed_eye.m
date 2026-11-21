load wind

root = fileparts(fileparts(mfilename('fullpath')));
output = fullfile(root,'artifacts','Path22_Seed_Eye.gif');
[sx,sy,sz] = meshgrid(80,18:0.5:22,4:0.5:8);
paths = stream3(x,y,z,u,v,w,sx,sy,sz,[0.1 20000]);
seedY = sy(:);
seedZ = sz(:);
centerId = find(abs(seedY-20) < 1e-12 & abs(seedZ-6) < 1e-12);
assert(isscalar(centerId),'Center seed must occur exactly once');
lengths = cellfun(@(p) size(p,1),paths);

fig = figure('Visible','off','Color',[0.015 0.025 0.06], ...
    'Position',[0 0 1280 720],'InvertHardcopy','off');
ax = axes('Parent',fig,'Position',[0.055 0.10 0.84 0.84], ...
    'Color',[0.015 0.025 0.06]);
hold(ax,'on');

traces = gobjects(numel(paths),1);
for k = 1:numel(paths)
    distance = hypot(seedY(k)-20,seedZ(k)-6);
    mix = min(distance / hypot(2,2),1);
    color = (1-mix) * [0.93 1.00 0.72] + mix * [0.10 0.42 0.78];
    width = 1.0;
    if k == centerId
        width = 3.4;
    end
    traces(k) = plot3(ax,NaN,NaN,NaN,'Color',color,'LineWidth',width);
end

xlim(ax,[78 122]);
ylim(ax,[17.5 32]);
zlim(ax,[2.5 7]);
grid(ax,'on'); box(ax,'on');
ax.GridColor = [0.7 0.8 1.0];
ax.GridAlpha = 0.14;
ax.XColor = [0.75 0.82 0.95];
ax.YColor = [0.75 0.82 0.95];
ax.ZColor = [0.75 0.82 0.95];
camproj(ax,'perspective');
xlabel(ax,'x'); ylabel(ax,'y'); zlabel(ax,'z');

seed = [80 20 6];
channelCenter = [111.82069301377661 23.499019382170342 2.7458635653533694];
scatter3(ax,seed(1),seed(2),seed(3),70,[0.93 1.00 0.72],'filled');
scatter3(ax,channelCenter(1),channelCenter(2),channelCenter(3),55, ...
    [0.35 0.85 1.00],'filled','MarkerEdgeColor','white');
look = channelCenter-seed;
look = look/norm(look);
campos(ax,seed-1.5*look);
camtarget(ax,channelCenter);
camup(ax,[0 0 1]);
camva(ax,8);

title(ax,'Seed-eye view: looking from (80,20,6) into the recurrent channel', ...
    'Color','white','FontSize',16,'FontWeight','bold');
subtitleHandle = subtitle(ax,'Measured interior field · no exterior boundary condition', ...
    'Color',[0.75 0.84 1.0]);
statusHandle = text(ax,0.02,0.02,'','Units','normalized', ...
    'Color',[0.88 0.94 1.0],'FontName','Menlo','FontSize',10, ...
    'VerticalAlignment','bottom');

targets = unique(round(linspace(1,max(lengths),96)));
releaseLag = 220;
for frameIndex = 1:numel(targets)
    target = targets(frameIndex);
    active = 0;
    exited = 0;
    for k = 1:numel(paths)
        path = paths{k};
        n = size(path,1);
        if target > n + releaseLag
            set(traces(k),'XData',NaN,'YData',NaN,'ZData',NaN);
            exited = exited+1;
        else
            reached = min(target,n);
            first = max(1,reached-219);
            visible = path(first:reached,:);
            set(traces(k),'XData',visible(:,1),'YData',visible(:,2),'ZData',visible(:,3));
            active = active+double(target <= n);
            exited = exited+double(target > n);
        end
    end
    if target < 1176
        state = 'approaching';
    elseif target <= 1770
        state = 'returning and rotating';
    elseif target <= lengths(centerId)
        state = 'opening toward lower-y exit';
    else
        state = 'post-field unresolved';
    end
    subtitleHandle.String = sprintf('sample %d · center path %s',target,state);
    statusHandle.String = sprintf('active %d · exited %d\nview direction fixed at the original seed',active,exited);
    drawnow;
    rgb = print(fig,'-RGBImage','-r100');
    [indexed,map] = rgb2ind(rgb,256,'nodither');
    if frameIndex == 1
        imwrite(indexed,map,output,'gif','LoopCount',Inf,'DelayTime',0.065);
    else
        imwrite(indexed,map,output,'gif','WriteMode','append','DelayTime',0.065);
    end
end

for holdFrame = 1:12
    subtitleHandle.String = 'The measured field ends · continuation and disappearance remain open';
    drawnow;
    rgb = print(fig,'-RGBImage','-r100');
    [indexed,map] = rgb2ind(rgb,256,'nodither');
    imwrite(indexed,map,output,'gif','WriteMode','append','DelayTime',0.09);
end
close(fig);
fprintf('SEED_EYE_GIF=%s FRAMES=%d\n',output,numel(targets)+12);
