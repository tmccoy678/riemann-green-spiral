load wind
[sx,sy,sz] = meshgrid(80,20:5:50,0:2:12);
paths = stream3(x,y,z,u,v,w,sx,sy,sz);

root = fileparts(fileparts(mfilename('fullpath')));
output = fullfile(root,'data','riemann_paths.tsv');
fid = fopen(output,'w');
assert(fid ~= -1,'Unable to open trajectory export');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'path_id\tpoint_id\tx\ty\tz\n');
for path_id = 1:numel(paths)
    path = paths{path_id};
    for point_id = 1:size(path,1)
        fprintf(fid,'%d\t%d\t%.17g\t%.17g\t%.17g\n', ...
            path_id,point_id,path(point_id,1),path(point_id,2),path(point_id,3));
    end
end

lengths = cellfun(@(p) size(p,1),paths);
fprintf('PATHS=%d NONEMPTY=%d MIN=%d MAX=%d TOTAL_POINTS=%d\n', ...
    numel(paths),nnz(lengths),min(lengths(lengths>0)),max(lengths),sum(lengths));
