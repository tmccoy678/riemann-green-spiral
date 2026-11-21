load wind

root = fileparts(fileparts(mfilename('fullpath')));
sourceTable = readtable(fullfile(root,'data','riemann_paths.tsv'), ...
    'FileType','text','Delimiter','\t');
path22 = sourceTable(sourceTable.path_id == 22,:);
p = [path22.x,path22.y,path22.z];

vx = interp3(x,y,z,u,p(:,1),p(:,2),p(:,3),'linear',NaN);
vy = interp3(x,y,z,v,p(:,1),p(:,2),p(:,3),'linear',NaN);
vz = interp3(x,y,z,w,p(:,1),p(:,2),p(:,3),'linear',NaN);
speed = sqrt(vx.^2 + vy.^2 + vz.^2);
assert(all(isfinite(speed)),'Every path-22 point must interpolate in the field');

flowOutput = fullfile(root,'data','path22_flow.tsv');
fid = fopen(flowOutput,'w');
assert(fid ~= -1,'Unable to open path-22 flow export');
cleanupFlow = onCleanup(@() fclose(fid));
fprintf(fid,'point_id\tx\ty\tz\tu\tv\tw\tspeed\n');
for point_id = 1:height(path22)
    fprintf(fid,'%d\t%.17g\t%.17g\t%.17g\t%.17g\t%.17g\t%.17g\t%.17g\n', ...
        point_id,p(point_id,1),p(point_id,2),p(point_id,3), ...
        vx(point_id),vy(point_id),vz(point_id),speed(point_id));
end
clear cleanupFlow

metaOutput = fullfile(root,'data','path22_field_meta.tsv');
fid = fopen(metaOutput,'w');
assert(fid ~= -1,'Unable to open field metadata export');
cleanupMeta = onCleanup(@() fclose(fid));
fprintf(fid,'metric\tvalue\n');
fprintf(fid,'field_x_min\t%.17g\n',min(x(:)));
fprintf(fid,'field_x_max\t%.17g\n',max(x(:)));
fprintf(fid,'field_y_min\t%.17g\n',min(y(:)));
fprintf(fid,'field_y_max\t%.17g\n',max(y(:)));
fprintf(fid,'field_z_min\t%.17g\n',min(z(:)));
fprintf(fid,'field_z_max\t%.17g\n',max(z(:)));
fprintf(fid,'field_speed_min\t%.17g\n',min(sqrt(u(:).^2 + v(:).^2 + w(:).^2)));
fprintf(fid,'field_speed_max\t%.17g\n',max(sqrt(u(:).^2 + v(:).^2 + w(:).^2)));
clear cleanupMeta

fprintf('PATH22_FLOW=%s ROWS=%d\n',flowOutput,height(path22));
fprintf('PATH22_FIELD_META=%s\n',metaOutput);
