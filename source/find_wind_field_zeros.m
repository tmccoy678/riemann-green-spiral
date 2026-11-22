load wind
assert(exist('lsqnonlin','file') == 2,'Optimization Toolbox lsqnonlin is required');

root = fileparts(fileparts(mfilename('fullpath')));
output = fullfile(root,'data','wind_field_zeros.tsv');
pathTable = readtable(fullfile(root,'data','riemann_paths.tsv'), ...
    'FileType','text','Delimiter','\t');
path22 = [pathTable.x(pathTable.path_id == 22), ...
    pathTable.y(pathTable.path_id == 22), ...
    pathTable.z(pathTable.path_id == 22)];

speed = sqrt(u.^2 + v.^2 + w.^2);
[~,order] = sort(speed(:),'ascend');
top = order(1:min(200,numel(order)));
seeds = [x(top),y(top),z(top)];
[i1,i2,i3] = ndgrid(1:6:size(x,1),1:6:size(x,2),1:3:size(x,3));
coarse = sub2ind(size(x),i1(:),i2(:),i3(:));
seeds = unique([seeds; x(coarse),y(coarse),z(coarse)],'rows');

lower = [min(x(:)),min(y(:)),min(z(:))];
upper = [max(x(:)),max(y(:)),max(z(:))];
field = @(p) [interp3(x,y,z,u,p(1),p(2),p(3),'linear'); ...
    interp3(x,y,z,v,p(1),p(2),p(3),'linear'); ...
    interp3(x,y,z,w,p(1),p(2),p(3),'linear')];
options = optimoptions('lsqnonlin','Display','off', ...
    'FunctionTolerance',1e-14,'StepTolerance',1e-14, ...
    'OptimalityTolerance',1e-14,'MaxIterations',200,'MaxFunctionEvaluations',1000);

solutions = zeros(0,3);
for k = 1:size(seeds,1)
    [candidate,resnorm,~,exitflag] = lsqnonlin(field,seeds(k,:),lower,upper,options);
    if exitflag > 0 && sqrt(resnorm) < 1e-8
        if isempty(solutions) || all(vecnorm(solutions-candidate,2,2) > 1e-5)
            solutions(end+1,:) = candidate; %#ok<AGROW>
        end
    end
end
solutions = sortrows(solutions,[1 2 3]);
assert(size(solutions,1) == 19,'Expected nineteen distinct zeros');

xAxis = squeeze(x(1,:,1));
yAxis = squeeze(y(:,1,1));
zAxis = squeeze(z(1,1,:));
labels = {'000','100','010','110','001','101','011','111'};

fid = fopen(output,'w');
assert(fid ~= -1,'Unable to open zero atlas export');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,['zero_id\tx\ty\tz\tresidual\tcell_ix\tcell_iy\tcell_iz\t' ...
    'x0\tx1\ty0\ty1\tz0\tz1\ttx\tty\ttz\tspiral\t' ...
    'nearest_path_distance\tnearest_path_sample\t' ...
    'j11\tj12\tj13\tj21\tj22\tj23\tj31\tj32\tj33\t' ...
    'e1_real\te1_imag\te2_real\te2_imag\te3_real\te3_imag']);
for label = labels
    fprintf(fid,'\tu%s\tv%s\tw%s',label{1},label{1},label{1});
end
fprintf(fid,'\n');

h = 1e-4;
spiralCount = 0;
for zeroId = 1:size(solutions,1)
    p = solutions(zeroId,:);
    residual = norm(field(p));
    ix = find(xAxis <= p(1),1,'last'); ix = min(ix,numel(xAxis)-1);
    iy = find(yAxis <= p(2),1,'last'); iy = min(iy,numel(yAxis)-1);
    iz = find(zAxis <= p(3),1,'last'); iz = min(iz,numel(zAxis)-1);
    x0 = xAxis(ix); x1 = xAxis(ix+1);
    y0 = yAxis(iy); y1 = yAxis(iy+1);
    z0 = zAxis(iz); z1 = zAxis(iz+1);
    local = [(p(1)-x0)/(x1-x0),(p(2)-y0)/(y1-y0),(p(3)-z0)/(z1-z0)];

    corners = zeros(8,3);
    cornerId = 0;
    for dz = 0:1
        for dy = 0:1
            for dx = 0:1
                cornerId = cornerId+1;
                corners(cornerId,:) = [u(iy+dy,ix+dx,iz+dz), ...
                    v(iy+dy,ix+dx,iz+dz),w(iy+dy,ix+dx,iz+dz)];
            end
        end
    end

    J = zeros(3);
    for axis = 1:3
        delta = zeros(1,3); delta(axis) = h;
        J(:,axis) = (field(p+delta)-field(p-delta))/(2*h);
    end
    values = eig(J);
    isSpiral = any(abs(imag(values)) > 1e-7);
    spiralCount = spiralCount+isSpiral;
    if isSpiral
        positive = find(imag(values) > 1e-7,1);
        negative = find(imag(values) < -1e-7,1);
        realId = find(abs(imag(values)) <= 1e-7,1);
        values = values([positive negative realId]);
    else
        [~,orderReal] = sort(real(values));
        values = values(orderReal);
    end
    [nearestDistance,nearestSample] = min(vecnorm(path22-p,2,2));

    fprintf(fid,'%d',zeroId);
    fprintf(fid,'\t%.17g',[p,residual,ix,iy,iz,x0,x1,y0,y1,z0,z1,local,isSpiral, ...
        nearestDistance,nearestSample,reshape(J',1,9), ...
        real(values(1)),imag(values(1)),real(values(2)),imag(values(2)), ...
        real(values(3)),imag(values(3)),reshape(corners',1,24)]);
    fprintf(fid,'\n');
end
clear cleanup
assert(spiralCount == 9,'Expected nine spiral zeros');
fprintf('ZERO_ATLAS=%s ZEROS=%d SPIRAL=%d SEEDS=%d\n', ...
    output,size(solutions,1),spiralCount,size(seeds,1));
