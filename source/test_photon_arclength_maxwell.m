load wind
root = fileparts(fileparts(mfilename('fullpath')));
paths = readtable(fullfile(root,'data','riemann_paths.tsv'), ...
    'FileType','text','Delimiter','\t');
path22 = paths(paths.path_id == 22,:);
point = [path22.x,path22.y,path22.z];
first = 1176;
last = 1770;
source = point(first,:);
target = point(last,:);
arcLength = sum(vecnorm(diff(point(first:last,:),1,1),2,2));

initial = [source';reshape(eye(3),9,1);0];
options = odeset('RelTol',1e-10,'AbsTol',1e-12,'MaxStep',0.1);
[~,state] = ode113(@(s,state) photonRhs(state,x,y,z,u,v,w), ...
    [0,arcLength],initial,options);
final = state(end,:).';
endpoint = final(1:3).';
fundamental = reshape(final(4:12),3,3);
integratedDivergence = final(13);
endpointError = norm(endpoint-target);

tangent0 = unitWind(source,x,y,z,u,v,w).';
tangent1 = unitWind(endpoint,x,y,z,u,v,w).';
basis0 = null(tangent0');
basis1 = null(tangent1');
transverse = basis1'*fundamental*basis0;
areaScale = abs(det(transverse));
densityMultiplier = 1/areaScale;
autonomyResidual = norm(fundamental*tangent0-tangent1);
logDeterminant = log(abs(det(fundamental)));
liouvilleResidual = logDeterminant-integratedDivergence;

fid = fopen(fullfile(root,'data','photon_arclength_maxwell_receipt.txt'),'w');
assert(fid ~= -1,'Unable to open photon arclength receipt');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'PHOTON_ARCLENGTH_MAXWELL_COMPATIBILITY\n');
fprintf(fid,'channel_start=%d\nchannel_end=%d\n',first,last);
fprintf(fid,'stored_arc_length=%.17g\n',arcLength);
fprintf(fid,'endpoint_error=%.17g\n',endpointError);
fprintf(fid,'autonomy_residual=%.17g\n',autonomyResidual);
fprintf(fid,'log_abs_determinant=%.17g\n',logDeterminant);
fprintf(fid,'integrated_divergence=%.17g\n',integratedDivergence);
fprintf(fid,'liouville_residual=%.17g\n',liouvilleResidual);
fprintf(fid,'transverse_area_scale=%.17g\n',areaScale);
fprintf(fid,'energy_density_multiplier=%.17g\n',densityMultiplier);
fprintf(fid,'positive_density=%d\n',isfinite(densityMultiplier) && densityMultiplier>0);
fprintf(fid,'local_poynting_realizability=%s\n', ...
    string(endpointError<0.1 && autonomyResidual<0.05 && abs(liouvilleResidual)<1e-6));
fprintf(fid,'global_source_free_maxwell_field=unresolved\n');
clear cleanup

fprintf(['ENDPOINT_ERROR=%.17g AUTONOMY_RESIDUAL=%.17g ' ...
    'LIOUVILLE_RESIDUAL=%.17g AREA_SCALE=%.17g ' ...
    'DENSITY_MULTIPLIER=%.17g\n'],endpointError,autonomyResidual, ...
    liouvilleResidual,areaScale,densityMultiplier);

function derivative = photonRhs(state,x,y,z,u,v,w)
point = state(1:3).';
fundamental = reshape(state(4:12),3,3);
direction = unitWind(point,x,y,z,u,v,w);
h = 1e-4;
J = zeros(3);
for axis = 1:3
    offset = zeros(1,3);
    offset(axis) = h;
    J(:,axis) = (unitWind(point+offset,x,y,z,u,v,w)- ...
        unitWind(point-offset,x,y,z,u,v,w))'/(2*h);
end
derivative = [direction';reshape(J*fundamental,9,1);trace(J)];
end

function direction = unitWind(point,x,y,z,u,v,w)
velocity = [interp3(x,y,z,u,point(1),point(2),point(3),'linear'), ...
    interp3(x,y,z,v,point(1),point(2),point(3),'linear'), ...
    interp3(x,y,z,w,point(1),point(2),point(3),'linear')];
direction = velocity/norm(velocity);
end
