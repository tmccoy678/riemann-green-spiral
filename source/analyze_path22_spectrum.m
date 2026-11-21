root = fileparts(fileparts(mfilename('fullpath')));
T = readtable(fullfile(root,'data','riemann_paths.tsv'), ...
    'FileType','text','Delimiter','\t');
P = [T.x(T.path_id == 22),T.y(T.path_id == 22),T.z(T.path_id == 22)];

segments = [1176 1376; 1376 1601; 1601 1770; 1176 1770; 1770 2677];
names = {'return_1','return_2','return_3','channel','post_channel'};
output = fullfile(root,'data','path22_spectrum.tsv');
channelFixed = [];
fid = fopen(output,'w');
assert(fid ~= -1,'Unable to open spectral export');
cleanup = onCleanup(@() fclose(fid));

fprintf(fid,['segment\tstart\tend\ttransitions\trmse\ttrace\tdeterminant\tcondition\t' ...
    'fixed_x\tfixed_y\tfixed_z\t' ...
    'a11\ta12\ta13\ta21\ta22\ta23\ta31\ta32\ta33\t' ...
    'c1\tc2\tc3\t' ...
    'spiral_real\tspiral_imag\tspiral_magnitude\tspiral_log_magnitude\t' ...
    'spiral_angle\tspiral_vertical_participation\t' ...
    'vertical_real\tvertical_magnitude\tvertical_log_magnitude\t' ...
    'vertical_participation\trotation_period\trotations_in_segment\t' ...
    'plane_log_total\tvertical_log_total\tnet_log_total\n']);

for s = 1:size(segments,1)
    a = segments(s,1); b = segments(s,2); n = b-a;
    design = [P(a:b-1,:),ones(n,1)];
    target = P(a+1:b,:);
    coefficients = design \ target;
    A = coefficients(1:3,:)';
    offset = coefficients(4,:)';
    residual = target - design * coefficients;
    rmse = sqrt(mean(sum(residual.^2,2)));
    [vectors,diagonal] = eig(A);
    values = diag(diagonal);
    spiralId = find(imag(values) > 1e-12,1);
    verticalId = find(abs(imag(values)) <= 1e-12,1);
    assert(~isempty(spiralId) && ~isempty(verticalId), ...
        'Expected one complex pair and one real mode');
    spiral = values(spiralId);
    vertical = values(verticalId);
    fixed = (eye(3)-A) \ offset;
    if strcmp(names{s},'channel')
        channelFixed = fixed;
    end
    period = 2*pi/abs(angle(spiral));
    rotations = n/period;
    spiralLog = log(abs(spiral));
    verticalLog = log(abs(vertical));
    planeTotal = 2*n*spiralLog;
    verticalTotal = n*verticalLog;
    netTotal = planeTotal + verticalTotal;

    valuesOut = [a,b,n,rmse,trace(A),det(A),cond(design),fixed', ...
        reshape(A',1,9),offset',real(spiral),imag(spiral),abs(spiral), ...
        spiralLog,angle(spiral),abs(vectors(3,spiralId)), ...
        real(vertical),abs(vertical),verticalLog,abs(vectors(3,verticalId)), ...
        period,rotations,planeTotal,verticalTotal,netTotal];
    fprintf(fid,'%s',names{s});
    fprintf(fid,'\t%.17g',valuesOut);
    fprintf(fid,'\n');
end
clear cleanup

assert(~isempty(channelFixed),'Channel fixed point was not recorded');
poincareOutput = fullfile(root,'data','path22_poincare.tsv');
fid = fopen(poincareOutput,'w');
assert(fid ~= -1,'Unable to open Poincare crossing export');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'crossing_id\tfrom_sample\torientation\tx\ty\tz\n');
crossingId = 0;
sectionX = channelFixed(1);
for pointId = 1176:1769
    left = P(pointId,1)-sectionX;
    right = P(pointId+1,1)-sectionX;
    if left == 0 || left*right < 0
        if left == 0
            fraction = 0;
        else
            fraction = -left/(right-left);
        end
        crossing = P(pointId,:) + fraction*(P(pointId+1,:)-P(pointId,:));
        orientation = sign(P(pointId+1,1)-P(pointId,1));
        crossingId = crossingId+1;
        fprintf(fid,'%d\t%d\t%d\t%.17g\t%.17g\t%.17g\n', ...
            crossingId,pointId,orientation,crossing(1),crossing(2),crossing(3));
    end
end
clear cleanup
assert(crossingId == 16,'Expected sixteen interior Poincare crossings');

channel = readtable(output,'FileType','text','Delimiter','\t', ...
    'VariableNamingRule','preserve');
channel = channel(strcmp(channel.segment,'channel'),:);
fprintf('SPECTRUM=%s\n',output);
fprintf('POINCARE=%s CROSSINGS=%d\n',poincareOutput,crossingId);
fprintf('CHANNEL_ROTATIONS=%.12f PLANE_LOG=%.12f VERTICAL_LOG=%.12f NET_LOG=%.12f\n', ...
    channel.rotations_in_segment,channel.plane_log_total, ...
    channel.vertical_log_total,channel.net_log_total);
