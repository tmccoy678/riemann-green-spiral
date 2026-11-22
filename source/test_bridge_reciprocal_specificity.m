root = fileparts(fileparts(mfilename('fullpath')));
paths = readtable(fullfile(root,'data','riemann_paths.tsv'), ...
    'FileType','text','Delimiter','\t');
spectrum = readtable(fullfile(root,'data','path22_spectrum.tsv'), ...
    'FileType','text','Delimiter','\t');
channel = spectrum(strcmp(spectrum.segment,'channel'),:);

windowPoints = 595;
stride = 100;
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
writetable(result,fullfile(root,'data','bridge_reciprocal_specificity.tsv'), ...
    'FileType','text','Delimiter','\t');

channelSecond = channel.a11*channel.a22+channel.a11*channel.a33+ ...
    channel.a22*channel.a33-channel.a12*channel.a21- ...
    channel.a13*channel.a31-channel.a23*channel.a32;
channelTraceDefect = abs(channel.trace-channelSecond);
channelDeterminantDefect = abs(1-channel.determinant);
combined = result.trace_reciprocal_defect+result.determinant_reciprocal_defect;
channelCombined = channelTraceDefect+channelDeterminantDefect;
rank = sum(combined <= channelCombined);
fprintf(['WINDOWS=%d CHANNEL_TRACE_DEFECT=%.17g ' ...
    'CHANNEL_DETERMINANT_DEFECT=%.17g CHANNEL_COMBINED=%.17g ' ...
    'SMALLER_OR_EQUAL=%d FRACTION=%.17g MEDIAN=%.17g\n'], ...
    height(result),channelTraceDefect,channelDeterminantDefect, ...
    channelCombined,rank,rank/height(result),median(combined));
