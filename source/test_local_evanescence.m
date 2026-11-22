root = fileparts(fileparts(mfilename('fullpath')));
run(fullfile(root,'source','test_source_free_maxwell_field.m'))
bundle = readtable(fullfile(root,'data','photon_neighbor_bundle.tsv'), ...
    'FileType','text','Delimiter','\t');
selected = bundle(ismember(bundle.cycle,[7,8,9]),:);
planeX = 111.82069301377661;

amplitude = sqrt(electricX.^2+electricY.^2+electricZ.^2+ ...
    magneticX.^2+magneticY.^2+magneticZ.^2);
amplitudeField = griddedInterpolant({xAxis,yAxis,zAxis},amplitude,'linear','none');
directionFields = { ...
    griddedInterpolant({xAxis,yAxis,zAxis},directionX,'linear','none'), ...
    griddedInterpolant({xAxis,yAxis,zAxis},directionY,'linear','none'), ...
    griddedInterpolant({xAxis,yAxis,zAxis},directionZ,'linear','none')};
poyntingFields = { ...
    griddedInterpolant({xAxis,yAxis,zAxis},poyntingX,'linear','none'), ...
    griddedInterpolant({xAxis,yAxis,zAxis},poyntingY,'linear','none'), ...
    griddedInterpolant({xAxis,yAxis,zAxis},poyntingZ,'linear','none')};

distance = (0.15:0.1:1.15)';
rayNames = {'normal_1_positive','normal_1_negative', ...
    'normal_2_positive','normal_2_negative'};
rows = zeros(height(selected)*4,9);
row = 0;
for cycleIndex = 1:height(selected)
    center = [planeX,selected.centroid_y(cycleIndex),selected.centroid_z(cycleIndex)];
    tangent = [directionFields{1}(center),directionFields{2}(center), ...
        directionFields{3}(center)];
    tangent = tangent/norm(tangent);
    reference = [0,0,1];
    if abs(dot(tangent,reference))>0.9, reference=[0,1,0]; end
    normal1 = cross(tangent,reference); normal1=normal1/norm(normal1);
    normal2 = cross(tangent,normal1); normal2=normal2/norm(normal2);
    rays = [normal1;-normal1;normal2;-normal2];
    for rayIndex = 1:4
        row = row+1;
        point = center+distance.*rays(rayIndex,:);
        value = amplitudeField(point);
        logValue = log(value);
        exponential = polyfit(distance,logValue,1);
        gaussian = polyfit(distance.^2,logValue,1);
        fittedExp = polyval(exponential,distance);
        fittedGaussian = polyval(gaussian,distance.^2);
        total = sum((logValue-mean(logValue)).^2);
        expR2 = 1-sum((logValue-fittedExp).^2)/total;
        gaussianR2 = 1-sum((logValue-fittedGaussian).^2)/total;
        poynting = [poyntingFields{1}(point),poyntingFields{2}(point), ...
            poyntingFields{3}(point)];
        poyntingMagnitude = vecnorm(poynting,2,2);
        alignment = (poynting*tangent')./poyntingMagnitude;
        monotonicFraction = sum(diff(value)<0)/(numel(value)-1);
        rows(row,:) = [selected.cycle(cycleIndex),rayIndex, ...
            -exponential(1),expR2,-gaussian(1),gaussianR2, ...
            monotonicFraction,mean(alignment),min(alignment)];
    end
end

result = array2table(rows,'VariableNames',{'cycle','ray_id','kappa', ...
    'exponential_r2','gaussian_q','gaussian_r2','monotonic_fraction', ...
    'mean_tangential_alignment','minimum_tangential_alignment'});
result.ray = repmat(rayNames',height(selected),1);
result = movevars(result,'ray','After','ray_id');
result.evanescent_local = result.kappa>0 & result.exponential_r2>=0.95 & ...
    result.monotonic_fraction>=0.8 & result.mean_tangential_alignment>=0.8;
writetable(result,fullfile(root,'data','local_evanescence.tsv'), ...
    'FileType','text','Delimiter','\t');

fid = fopen(fullfile(root,'data','local_evanescence_receipt.txt'),'w');
assert(fid~=-1,'Unable to open evanescence receipt');
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'LOCAL_EVANESCENCE_CYCLES_7_8_9\n');
fprintf(fid,'sections=3\nrays_per_section=4\n');
fprintf(fid,'evanescent_rays=%d\n',sum(result.evanescent_local));
fprintf(fid,'total_rays=%d\n',height(result));
fprintf(fid,'median_kappa=%.17g\n',median(result.kappa));
fprintf(fid,'median_exponential_r2=%.17g\n',median(result.exponential_r2));
fprintf(fid,'median_gaussian_r2=%.17g\n',median(result.gaussian_r2));
fprintf(fid,'minimum_mean_tangential_alignment=%.17g\n',min(result.mean_tangential_alignment));
fprintf(fid,'criterion=kappa_positive,exponential_r2_at_least_0.95,monotonic_fraction_at_least_0.8,mean_tangential_alignment_at_least_0.8\n');
clear cleanup

fprintf(['EVANESCENT_RAYS=%d/%d MEDIAN_KAPPA=%.9f ' ...
    'EXP_R2=%.6f GAUSS_R2=%.6f MIN_TANGENTIAL=%.6f\n'], ...
    sum(result.evanescent_local),height(result),median(result.kappa), ...
    median(result.exponential_r2),median(result.gaussian_r2), ...
    min(result.mean_tangential_alignment));
