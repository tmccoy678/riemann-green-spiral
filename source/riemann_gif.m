load wind
speed = sqrt(u.^2 + v.^2 + w.^2);
root = fileparts(fileparts(mfilename('fullpath')));
output = fullfile(root,'artifacts','Blu_Wet_Body_Fluid_Planes.gif');

fig = figure('Visible','off','Color',[0.015 0.025 0.06], ...
    'Position',[0 0 1280 720],'InvertHardcopy','off');
ax = axes('Parent',fig,'Position',[0.055 0.10 0.84 0.84], ...
    'Color',[0.015 0.025 0.06]);
planes = slice(ax,x,y,z,speed,[80 100],[],[1 5 10]);
set(planes,'EdgeColor','none','FaceAlpha',0.36);
shading(ax,'interp');
colormap(ax,turbo(256));
hold(ax,'on');

[sx,sy,sz] = meshgrid(80,20:5:50,0:2:12);
paths = stream3(x,y,z,u,v,w,sx,sy,sz);
colors = turbo(max(numel(paths),2));
traces = gobjects(numel(paths),1);
for k = 1:numel(paths)
    traces(k) = animatedline(ax,'Color',colors(k,:), ...
        'LineWidth',2.0,'MaximumNumPoints',220);
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
title(ax,'One continuous fluid body forming through its field', ...
    'Color','white','FontSize',18,'FontWeight','bold');
subtitle(ax,'MATLAB native velocity planes and trajectories', ...
    'Color',[0.75 0.84 1.0]);

lengths = cellfun(@(p) size(p,1),paths);
max_length = max(lengths);
frames = unique(round(linspace(1,max_length,84)));
previous = 0;
for frame_index = 1:numel(frames)
    target = frames(frame_index);
    for step = previous+1:target
        for k = 1:numel(paths)
            if step <= lengths(k)
                p = paths{k};
                addpoints(traces(k),p(step,1),p(step,2),p(step,3));
            end
        end
    end
    previous = target;
    drawnow;
    rgb = print(fig,'-RGBImage','-r100');
    [indexed,map] = rgb2ind(rgb,256,'nodither');
    if frame_index == 1
        imwrite(indexed,map,output,'gif','LoopCount',Inf,'DelayTime',0.055);
    else
        imwrite(indexed,map,output,'gif','WriteMode','append','DelayTime',0.055);
    end
end

for hold_frame = 1:12
    rgb = print(fig,'-RGBImage','-r100');
    [indexed,map] = rgb2ind(rgb,256,'nodither');
    imwrite(indexed,map,output,'gif','WriteMode','append','DelayTime',0.055);
end
close(fig);
fprintf('GIF=%s\n',output);
