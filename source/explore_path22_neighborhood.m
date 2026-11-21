load wind

root = fileparts(fileparts(mfilename('fullpath')));
dataOutput = fullfile(root,'data','path22_neighborhood_0125.tsv');
seedOutput = fullfile(root,'data','path22_neighborhood_seeds.tsv');
gifOutput = fullfile(root,'artifacts','Path22_Field_Exit.gif');

seedYValues = 18:0.125:22;
seedZValues = 4:0.125:8;
[sx,sy,sz] = meshgrid(80,seedYValues,seedZValues);
seedY = sy(:);
seedZ = sz(:);
paths = stream3(x,y,z,u,v,w,sx,sy,sz,[0.1 20000]);
lengths = cellfun(@(p) size(p,1),paths);
assert(numel(paths) == 1089,'Unexpected neighborhood cardinality');

centerId = find(abs(seedY - 20) < 1e-12 & abs(seedZ - 6) < 1e-12);
assert(isscalar(centerId),'Original path-22 seed must occur exactly once');
assert(lengths(centerId) == 2677,'Center seed no longer matches path 22');

fid = fopen(dataOutput,'w');
assert(fid ~= -1,'Unable to open neighborhood path export');
cleanupData = onCleanup(@() fclose(fid));
fprintf(fid,'seed_id\tseed_y\tseed_z\tpoint_id\tx\ty\tz\n');
for seedId = 1:numel(paths)
    path = paths{seedId};
    n = size(path,1);
    block = [repmat(seedId,n,1),repmat(seedY(seedId),n,1), ...
        repmat(seedZ(seedId),n,1),(1:n)',path];
    fprintf(fid,'%d\t%.17g\t%.17g\t%d\t%.17g\t%.17g\t%.17g\n',block');
end
clear cleanupData

fieldBounds = [min(x(:)) max(x(:)); min(y(:)) max(y(:)); min(z(:)) max(z(:))];
fid = fopen(seedOutput,'w');
assert(fid ~= -1,'Unable to open neighborhood seed export');
cleanupSeed = onCleanup(@() fclose(fid));
fprintf(fid,'seed_id\tseed_y\tseed_z\tlength\tend_x\tend_y\tend_z\tnearest_boundary\tboundary_gap\n');
for seedId = 1:numel(paths)
    path = paths{seedId};
    endpoint = path(end,:);
    gaps = [endpoint(1)-fieldBounds(1,1),fieldBounds(1,2)-endpoint(1), ...
        endpoint(2)-fieldBounds(2,1),fieldBounds(2,2)-endpoint(2), ...
        endpoint(3)-fieldBounds(3,1),fieldBounds(3,2)-endpoint(3)];
    labels = {'x_min','x_max','y_min','y_max','z_min','z_max'};
    [gap,boundaryId] = min(gaps);
    fprintf(fid,'%d\t%.17g\t%.17g\t%d\t%.17g\t%.17g\t%.17g\t%s\t%.17g\n', ...
        seedId,seedY(seedId),seedZ(seedId),size(path,1), ...
        endpoint(1),endpoint(2),endpoint(3),labels{boundaryId},gap);
end
clear cleanupSeed

speedField = sqrt(u.^2 + v.^2 + w.^2);
fig = figure('Visible','off','Color',[0.015 0.025 0.06], ...
    'Position',[0 0 1280 720],'InvertHardcopy','off');
ax = axes('Parent',fig,'Position',[0.055 0.10 0.84 0.84], ...
    'Color',[0.015 0.025 0.06]);
planes = slice(ax,x,y,z,speedField,[80 100],[],[1 5 10]);
set(planes,'EdgeColor','none','FaceAlpha',0.28);
shading(ax,'interp');
colormap(ax,turbo(256));
hold(ax,'on');

gridY = round((seedY - 18) / 0.125);
gridZ = round((seedZ - 4) / 0.125);
selected = find(mod(gridY,4) == 0 & mod(gridZ,4) == 0);
selected = unique([selected; centerId]);
colors = turbo(numel(selected));
traces = gobjects(numel(selected),1);
for k = 1:numel(selected)
    seedId = selected(k);
    distance = hypot(seedY(seedId)-20,seedZ(seedId)-6);
    mix = min(distance / hypot(2,2),1);
    color = (1-mix) * [0.70 1.00 0.62] + mix * [0.10 0.42 0.78];
    width = 1.0;
    if seedId == centerId
        color = [0.93 1.00 0.72];
        width = 3.2;
    end
    traces(k) = plot3(ax,NaN,NaN,NaN,'Color',color,'LineWidth',width);
end

axis(ax,'tight');
view(ax,3);
grid(ax,'on'); box(ax,'on');
ax.GridColor = [0.7 0.8 1.0];
ax.GridAlpha = 0.16;
ax.XColor = [0.75 0.82 0.95];
ax.YColor = [0.75 0.82 0.95];
ax.ZColor = [0.75 0.82 0.95];
camproj(ax,'perspective');
xlabel(ax,'x'); ylabel(ax,'y'); zlabel(ax,'z');
title(ax,'Riemann neighborhood: recurrence, exit, and unresolved continuation', ...
    'Color','white','FontSize',16,'FontWeight','bold');
subtitleHandle = subtitle(ax,'Preparing field','Color',[0.75 0.84 1.0]);
statusHandle = text(ax,0.02,0.02,'','Units','normalized', ...
    'Color',[0.88 0.94 1.0],'FontName','Menlo','FontSize',10, ...
    'VerticalAlignment','bottom');

maxLength = max(lengths(selected));
targets = unique(round(linspace(1,maxLength,96)));
releaseLag = 220;
for frameIndex = 1:numel(targets)
    target = targets(frameIndex);
    active = 0;
    exited = 0;
    for k = 1:numel(selected)
        seedId = selected(k);
        path = paths{seedId};
        n = size(path,1);
        if target > n + releaseLag
            set(traces(k),'XData',NaN,'YData',NaN,'ZData',NaN);
            exited = exited + 1;
        else
            reached = min(target,n);
            first = max(1,reached-219);
            visible = path(first:reached,:);
            set(traces(k),'XData',visible(:,1),'YData',visible(:,2),'ZData',visible(:,3));
            active = active + double(target <= n);
            exited = exited + double(target > n);
        end
    end
    centerLength = lengths(centerId);
    if target < 1176
        centerStatus = 'APPROACHING RETURN CHANNEL';
    elseif target <= 1770
        centerStatus = 'RECURRENT CHANNEL';
    elseif target <= centerLength
        centerStatus = 'CONTINUING TOWARD FIELD BOUNDARY';
    else
        centerStatus = 'OUTSIDE FIELD: UNRESOLVED';
    end
    subtitleHandle.String = sprintf('sample target %d · center seed %s',target,centerStatus);
    statusHandle.String = sprintf('selected paths active %d · exited %d\ncomplete source paths remain in TSV',active,exited);
    drawnow;
    rgb = print(fig,'-RGBImage','-r100');
    [indexed,map] = rgb2ind(rgb,256,'nodither');
    if frameIndex == 1
        imwrite(indexed,map,gifOutput,'gif','LoopCount',Inf,'DelayTime',0.065);
    else
        imwrite(indexed,map,gifOutput,'gif','WriteMode','append','DelayTime',0.065);
    end
end

for holdFrame = 1:10
    subtitleHandle.String = 'Recorded path ends at field boundary · post-field outcome unresolved';
    drawnow;
    rgb = print(fig,'-RGBImage','-r100');
    [indexed,map] = rgb2ind(rgb,256,'nodither');
    imwrite(indexed,map,gifOutput,'gif','WriteMode','append','DelayTime',0.09);
end

for releaseFrame = 1:8
    fraction = releaseFrame / 8;
    centerTrace = traces(selected == centerId);
    centerTrace.Color = (1-fraction) * [0.93 1.00 0.72] + fraction * [0.015 0.025 0.06];
    subtitleHandle.String = 'Display releases the exited path · disappearance remains admissible, not asserted';
    drawnow;
    rgb = print(fig,'-RGBImage','-r100');
    [indexed,map] = rgb2ind(rgb,256,'nodither');
    imwrite(indexed,map,gifOutput,'gif','WriteMode','append','DelayTime',0.09);
end
close(fig);

fprintf('NEIGHBORHOOD_PATHS=%d TOTAL_POINTS=%d CENTER_ID=%d CENTER_LENGTH=%d\n', ...
    numel(paths),sum(lengths),centerId,lengths(centerId));
fprintf('NEIGHBORHOOD_DATA=%s\n',dataOutput);
fprintf('NEIGHBORHOOD_SEEDS=%s\n',seedOutput);
fprintf('NEIGHBORHOOD_GIF=%s\n',gifOutput);
