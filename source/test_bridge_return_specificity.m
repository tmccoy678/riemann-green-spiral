root = fileparts(fileparts(mfilename('fullpath')));
paths = readtable(fullfile(root,'data','riemann_paths.tsv'), ...
    'FileType','text','Delimiter','\t');
spectrum = readtable(fullfile(root,'data','path22_spectrum.tsv'), ...
    'FileType','text','Delimiter','\t');
target = spectrum(strcmp(spectrum.segment,'return_1'),:);

windowPoints = 201;
stride = 50;
rows = zeros(0,10);
for pathId = unique(paths.path_id)'
    selected = paths(paths.path_id == pathId,:);
    points = [selected.x,selected.y,selected.z];
    if size(points,1) < windowPoints
        continue
    end
    starts = unique([1:stride:(size(points,1)-windowPoints+1), ...
        size(points,1)-windowPoints+1]);
    for startId = starts
        segment = points(startId:startId+windowPoints-1,:);
        design = [segment(1:end-1,:),ones(windowPoints-1,1)];
        coefficients = design\segment(2:end,:);
        A = coefficients(1:3,:)';
        fitted = design*coefficients;
        rmse = sqrt(mean(sum((fitted-segment(2:end,:)).^2,2)));
        traceA = trace(A);
        secondA = A(1,1)*A(2,2)+A(1,1)*A(3,3)+A(2,2)*A(3,3) ...
            -A(1,2)*A(2,1)-A(1,3)*A(3,1)-A(2,3)*A(3,2);
        determinantA = det(A);
        traceDefect = abs(traceA-secondA);
        determinantDefect = abs(1-determinantA);
        rows(end+1,:) = [pathId,startId,startId+windowPoints-1,rmse, ...
            cond(design),traceA,secondA,determinantA,traceDefect, ...
            determinantDefect]; %#ok<AGROW>
    end
end

result = array2table(rows,'VariableNames',{'path_id','start_sample', ...
    'end_sample','rmse','condition','trace','second_coefficient', ...
    'determinant','trace_reciprocal_defect','determinant_reciprocal_defect'});
writetable(result,fullfile(root,'data','bridge_return_specificity.tsv'), ...
    'FileType','text','Delimiter','\t');

targetSecond = target.a11*target.a22+target.a11*target.a33+ ...
    target.a22*target.a33-target.a12*target.a21- ...
    target.a13*target.a31-target.a23*target.a32;
targetTraceDefect = abs(target.trace-targetSecond);
targetDeterminantDefect = abs(1-target.determinant);
combined = result.trace_reciprocal_defect+result.determinant_reciprocal_defect;
targetCombined = targetTraceDefect+targetDeterminantDefect;
rank = sum(combined <= targetCombined);
fprintf(['WINDOWS=%d PATHS=%d TARGET_TRACE_DEFECT=%.17g ' ...
    'TARGET_DETERMINANT_DEFECT=%.17g TARGET_COMBINED=%.17g ' ...
    'SMALLER_OR_EQUAL=%d FRACTION=%.17g MEDIAN=%.17g\n'], ...
    height(result),numel(unique(result.path_id)),targetTraceDefect, ...
    targetDeterminantDefect,targetCombined,rank,rank/height(result), ...
    median(combined));
