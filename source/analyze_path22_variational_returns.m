load wind
root = fileparts(fileparts(mfilename('fullpath')));
paths = readtable(fullfile(root,'data','riemann_paths.tsv'), ...
    'FileType','text','Delimiter','\t');
path22 = paths(paths.path_id == 22,:);
point = [path22.x,path22.y,path22.z];

names = {'return_1';'return_2';'return_3';'channel'};
starts = [1176;1376;1601;1176];
ends = [1376;1601;1770;1770];
rows = zeros(numel(starts),18);
h = 1e-4;

for segmentId = 1:numel(starts)
    first = starts(segmentId);
    last = ends(segmentId);
    fundamental = eye(3);
    integratedDivergence = 0;
    elapsed = 0;
    for sample = first:last-1
        midpoint = (point(sample,:)+point(sample+1,:))/2;
        velocity = windValue(midpoint,x,y,z,u,v,w);
        delta = point(sample+1,:)-point(sample,:);
        dt = dot(delta,velocity)/dot(velocity,velocity);
        J = zeros(3);
        for axis = 1:3
            offset = zeros(1,3);
            offset(axis) = h;
            J(:,axis) = (windValue(midpoint+offset,x,y,z,u,v,w)- ...
                windValue(midpoint-offset,x,y,z,u,v,w))'/(2*h);
        end
        fundamental = expm(J*dt)*fundamental;
        integratedDivergence = integratedDivergence+trace(J)*dt;
        elapsed = elapsed+dt;
    end
    determinant = det(fundamental);
    endpointDistance = norm(point(last,:)-point(first,:));
    rows(segmentId,:) = [first,last,last-first,elapsed,endpointDistance, ...
        determinant,log(abs(determinant)),integratedDivergence, ...
        log(abs(determinant))-integratedDivergence, ...
        reshape(fundamental',1,9)];
end

result = array2table(rows,'VariableNames',{'start_sample','end_sample', ...
    'transitions','elapsed_parameter','endpoint_distance','determinant', ...
    'log_abs_determinant','integrated_divergence','liouville_residual', ...
    'm11','m12','m13','m21','m22','m23','m31','m32','m33'});
result.leading_eigen_real = zeros(height(result),1);
result.leading_eigen_imag = zeros(height(result),1);
for eigenId = 1:3
    result.(sprintf('e%d_real',eigenId)) = zeros(height(result),1);
    result.(sprintf('e%d_imag',eigenId)) = zeros(height(result),1);
    result.(sprintf('e%d_magnitude',eigenId)) = zeros(height(result),1);
end
for segmentId = 1:height(result)
    M = [result.m11(segmentId),result.m12(segmentId),result.m13(segmentId); ...
        result.m21(segmentId),result.m22(segmentId),result.m23(segmentId); ...
        result.m31(segmentId),result.m32(segmentId),result.m33(segmentId)];
    values = eig(M);
    [~,order] = sort(abs(values),'descend');
    values = values(order);
    result.leading_eigen_real(segmentId) = real(values(1));
    result.leading_eigen_imag(segmentId) = imag(values(1));
    for eigenId = 1:3
        result.(sprintf('e%d_real',eigenId))(segmentId) = real(values(eigenId));
        result.(sprintf('e%d_imag',eigenId))(segmentId) = imag(values(eigenId));
        result.(sprintf('e%d_magnitude',eigenId))(segmentId) = abs(values(eigenId));
    end
end
result.segment = names;
result = movevars(result,'segment','Before','start_sample');
writetable(result,fullfile(root,'data','path22_variational_returns.tsv'), ...
    'FileType','text','Delimiter','\t');

channel = result(strcmp(result.segment,'channel'),:);
fprintf(['VARIATIONAL_CHANNEL_DET=%.17g LOGDET=%.17g ' ...
    'INTEGRATED_DIVERGENCE=%.17g LIOUVILLE_RESIDUAL=%.17g ' ...
    'EIGEN=%.17g%+.17gi\n'],channel.determinant, ...
    channel.log_abs_determinant,channel.integrated_divergence, ...
    channel.liouville_residual,channel.leading_eigen_real, ...
    channel.leading_eigen_imag);

function value = windValue(point,x,y,z,u,v,w)
value = [interp3(x,y,z,u,point(1),point(2),point(3),'linear'), ...
    interp3(x,y,z,v,point(1),point(2),point(3),'linear'), ...
    interp3(x,y,z,w,point(1),point(2),point(3),'linear')];
end
