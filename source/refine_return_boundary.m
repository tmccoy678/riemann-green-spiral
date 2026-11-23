load wind

root = fileparts(fileparts(mfilename('fullpath')));
ensemble = readtable( ...
    fullfile(root,'data','return_ensemble_first9.tsv'), ...
    'FileType','text','Delimiter','\t');
seeds = unique(ensemble(:,{'seed_id','seed_y','seed_z'}));

occupied = false(33,33);
iy = round((seeds.seed_y-18)/0.125)+1;
iz = round((seeds.seed_z-4)/0.125)+1;
occupied(sub2ind(size(occupied),iy,iz)) = true;

candidates = zeros(0,2);
mixedCells = 0;
for yIndex = 1:32
    for zIndex = 1:32
        corners = occupied(yIndex:yIndex+1,zIndex:zIndex+1);
        if any(corners,'all') && ~all(corners,'all')
            mixedCells = mixedCells+1;
            y0 = 18+(yIndex-1)*0.125;
            z0 = 4+(zIndex-1)*0.125;
            candidates = [candidates; ... %#ok<AGROW>
                y0+0.0625,z0;
                y0+0.0625,z0+0.0625;
                y0+0.0625,z0+0.125;
                y0,z0+0.0625;
                y0+0.125,z0+0.0625];
        end
    end
end
candidates = unique(candidates,'rows','stable');

sx = 80*ones(size(candidates,1),1);
sy = candidates(:,1);
sz = candidates(:,2);
paths = stream3(x,y,z,u,v,w,sx,sy,sz,[0.1 20000]);

output = fullfile(tempdir,'return_boundary_refinement.tsv');
fid = fopen(output,'w');
assert(fid~=-1,'Unable to open adaptive-refinement output');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'seed_id\tseed_y\tseed_z\tpoint_id\tx\ty\tz\n');
for seedId = 1:numel(paths)
    path = paths{seedId};
    block = [repmat(seedId,size(path,1),1), ...
        repmat(sy(seedId),size(path,1),1), ...
        repmat(sz(seedId),size(path,1),1),(1:size(path,1))',path];
    fprintf(fid,'%d\t%.17g\t%.17g\t%d\t%.17g\t%.17g\t%.17g\n',block');
end
clear cleanup

fprintf('MIXED_CELLS=%d REFINED_SEEDS=%d POINTS=%d OUTPUT=%s\n', ...
    mixedCells,numel(paths),sum(cellfun(@(path)size(path,1),paths)),output);
