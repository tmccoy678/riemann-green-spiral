root = fileparts(fileparts(mfilename('fullpath')));
paths = readtable(fullfile(root,'data','riemann_paths.tsv'), ...
    'FileType','text','Delimiter','\t');
evanescence = readtable(fullfile(root,'data','local_evanescence.tsv'), ...
    'FileType','text','Delimiter','\t');
path22 = paths(paths.path_id == 22,:);
point = [path22.x,path22.y,path22.z];
planeX = 111.82069301377661;
targetYZ = [24.904797789860265,4.3733377366610426];

stepLength = vecnorm(diff(point,1,1),2,2);
cumulativeArc = [0;cumsum(stepLength)];
crossings = zeros(0,4);
for sample = 1:size(point,1)-1
    left = point(sample,1)-planeX;
    right = point(sample+1,1)-planeX;
    if left <= 0 && 0 < right
        fraction = -left/(right-left);
        crossing = point(sample,:)+fraction*(point(sample+1,:)-point(sample,:));
        arc = cumulativeArc(sample)+fraction*stepLength(sample);
        crossings(end+1,:) = [crossing,arc]; %#ok<AGROW>
    end
end
[~,firstCycle] = min(vecnorm(crossings(:,2:3)-targetYZ,2,2));
cycleIds = (7:9)';
crossingRows = firstCycle+cycleIds-1;
arc = crossings(crossingRows,4);
arc = arc-arc(1);

selected = evanescence(ismember(evanescence.cycle,cycleIds) & ...
    strcmp(evanescence.ray,'normal_2_negative'),:);
selected = sortrows(selected,'cycle');
widthSquared = 1./(2*selected.gaussian_q);
fit = polyfit(arc,widthSquared,1);
predicted = polyval(fit,arc);
total = sum((widthSquared-mean(widthSquared)).^2);
rSquared = 1-sum((widthSquared-predicted).^2)/total;

result = table(cycleIds,arc,selected.gaussian_q,widthSquared,predicted, ...
    'VariableNames',{'cycle','arc_from_cycle_7','gaussian_q', ...
    'width_squared','linear_prediction'});
writetable(result,fullfile(root,'data','gaussian_width_growth.tsv'), ...
    'FileType','text','Delimiter','\t');

compatible = fit(1)>0 && rSquared>=0.95;
fid = fopen(fullfile(root,'data','gaussian_width_growth_receipt.txt'),'w');
assert(fid~=-1,'Unable to open Gaussian-width receipt');
cleanup=onCleanup(@() fclose(fid));
fprintf(fid,'GAUSSIAN_WIDTH_GROWTH_CYCLES_7_8_9\n');
fprintf(fid,'slope_per_arc=%.17g\n',fit(1));
fprintf(fid,'intercept=%.17g\n',fit(2));
fprintf(fid,'r_squared=%.17g\n',rSquared);
fprintf(fid,'positive_linear_growth=%d\n',fit(1)>0);
fprintf(fid,'diffusion_compatible=%d\n',compatible);
fprintf(fid,'criterion=positive_slope_and_r_squared_at_least_0.95\n');
clear cleanup

fprintf('WIDTH_SLOPE=%.12g R2=%.12g DIFFUSION_COMPATIBLE=%d\n', ...
    fit(1),rSquared,compatible);
