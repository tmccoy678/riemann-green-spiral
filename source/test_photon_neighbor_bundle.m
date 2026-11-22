load wind
root = fileparts(fileparts(mfilename('fullpath')));
neighborhood = readtable(fullfile(root,'data','path22_neighborhood_0125.tsv'), ...
    'FileType','text','Delimiter','\t');
planeX = 111.82069301377661;
targetYZ = [24.904797789860265,4.3733377366610426];
seedIds = [511,512,545,544];
crossings = cell(numel(seedIds),1);
starts = zeros(numel(seedIds),1);

for seedIndex = 1:numel(seedIds)
    selected = neighborhood(neighborhood.seed_id == seedIds(seedIndex),:);
    point = [selected.x,selected.y,selected.z];
    rows = zeros(0,3);
    for sample = 1:size(point,1)-1
        left = point(sample,1)-planeX;
        right = point(sample+1,1)-planeX;
        if left <= 0 && 0 < right
            fraction = -left/(right-left);
            crossing = point(sample,:)+fraction*(point(sample+1,:)-point(sample,:));
            rows(end+1,:) = crossing; %#ok<AGROW>
        end
    end
    crossings{seedIndex} = rows;
    [~,starts(seedIndex)] = min(vecnorm(rows(:,2:3)-targetYZ,2,2));
end

available = arrayfun(@(k) size(crossings{k},1)-starts(k)+1,1:numel(seedIds));
cycleCount = min(available);
rows = zeros(cycleCount,11);
referenceArea = NaN;
referenceFluxArea = NaN;
for cycle = 1:cycleCount
    yz = zeros(numel(seedIds),2);
    for seedIndex = 1:numel(seedIds)
        yz(seedIndex,:) = crossings{seedIndex}(starts(seedIndex)+cycle-1,2:3);
    end
    yCoord = yz(:,1);
    zCoord = yz(:,2);
    signedArea = 0.5*sum(yCoord.*zCoord([2:end,1])- ...
        zCoord.*yCoord([2:end,1]));
    area = abs(signedArea);
    if cycle == 1
        referenceArea = area;
    end
    centroid = mean(yz,1);
    velocity = [interp3(x,y,z,u,planeX,centroid(1),centroid(2),'linear'), ...
        interp3(x,y,z,v,planeX,centroid(1),centroid(2),'linear'), ...
        interp3(x,y,z,w,planeX,centroid(1),centroid(2),'linear')];
    directionX = abs(velocity(1))/norm(velocity);
    direction = velocity/norm(velocity);
    fluxArea = area*directionX;
    if cycle == 1
        referenceFluxArea = fluxArea;
    end
    energyDensity = referenceFluxArea/fluxArea;
    reference = [0,0,1];
    if abs(dot(direction,reference)) > 0.9
        reference = [0,1,0];
    end
    electricDirection = cross(direction,reference);
    electricDirection = electricDirection/norm(electricDirection);
    electric = sqrt(energyDensity)*electricDirection;
    magnetic = cross(direction,electric);
    poynting = cross(electric,magnetic);
    localMaxwellResidual = norm(poynting-energyDensity*direction);
    rows(cycle,:) = [cycle,centroid,area,signedArea, ...
        referenceArea/area,directionX,energyDensity,localMaxwellResidual, ...
        yz(3,:)-yz(1,:)];
end

result = array2table(rows,'VariableNames',{'cycle','centroid_y','centroid_z', ...
    'area','signed_area','projected_density_multiplier','direction_x', ...
    'flux_density_multiplier','local_maxwell_residual','diagonal_y','diagonal_z'});
writetable(result,fullfile(root,'data','photon_neighbor_bundle.tsv'), ...
    'FileType','text','Delimiter','\t');

[minimumArea,minimumIndex] = min(result.area);
fid = fopen(fullfile(root,'data','photon_neighbor_bundle_receipt.txt'),'w');
assert(fid ~= -1,'Unable to open photon neighbor receipt');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'PHOTON_NEIGHBOR_BUNDLE\n');
fprintf(fid,'seeds=511,512,545,544\n');
fprintf(fid,'plane_x=%.17g\n',planeX);
fprintf(fid,'positive_crossing_cycles=%d\n',height(result));
fprintf(fid,'reference_area=%.17g\n',referenceArea);
fprintf(fid,'minimum_area_cycle=%d\n',minimumIndex);
fprintf(fid,'minimum_area=%.17g\n',minimumArea);
fprintf(fid,'maximum_projected_density_multiplier=%.17g\n',max(result.projected_density_multiplier));
fprintf(fid,'maximum_flux_density_multiplier=%.17g\n',max(result.flux_density_multiplier));
fprintf(fid,'maximum_local_maxwell_residual=%.17g\n',max(result.local_maxwell_residual));
fprintf(fid,'local_null_field_poynting_compatibility=%d\n', ...
    max(result.local_maxwell_residual)<1e-12);
fprintf(fid,'orientation_flips=%d\n',sum(sign(result.signed_area(2:end)) ~= sign(result.signed_area(1:end-1))));
fprintf(fid,'interpretation=Measured neighboring streamlines provide a clock-free transverse ray-bundle test.\n');
clear cleanup

fprintf(['CYCLES=%d REFERENCE_AREA=%.17g MINIMUM_AREA=%.17g ' ...
    'MAX_DENSITY_MULTIPLIER=%.17g ORIENTATION_FLIPS=%d\n'], ...
    height(result),referenceArea,minimumArea,max(result.flux_density_multiplier), ...
    sum(sign(result.signed_area(2:end)) ~= sign(result.signed_area(1:end-1))));
