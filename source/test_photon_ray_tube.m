root = fileparts(fileparts(mfilename('fullpath')));
flow = readtable(fullfile(root,'data','path22_flow.tsv'), ...
    'FileType','text','Delimiter','\t');
returns = readtable(fullfile(root,'data','path22_variational_returns.tsv'), ...
    'FileType','text','Delimiter','\t');

rows = zeros(height(returns),8);
for k = 1:height(returns)
    M = [returns.m11(k),returns.m12(k),returns.m13(k); ...
        returns.m21(k),returns.m22(k),returns.m23(k); ...
        returns.m31(k),returns.m32(k),returns.m33(k)];
    first = returns.start_sample(k);
    last = returns.end_sample(k);
    velocity0 = [flow.u(first),flow.v(first),flow.w(first)]';
    velocity1 = [flow.u(last),flow.v(last),flow.w(last)]';
    speed0 = norm(velocity0);
    speed1 = norm(velocity1);
    tangent0 = velocity0/speed0;
    tangent1 = velocity1/speed1;
    basis0 = null(tangent0');
    basis1 = null(tangent1');
    transverseMap = basis1'*M*basis0;
    areaScale = abs(det(transverseMap));
    liouvilleAreaScale = abs(det(M))*speed0/speed1;
    areaResidual = areaScale-liouvilleAreaScale;
    autonomyResidual = norm(M*velocity0-velocity1)/speed1;
    rows(k,:) = [first,last,speed0,speed1,areaScale, ...
        liouvilleAreaScale,areaResidual,autonomyResidual];
end

result = array2table(rows,'VariableNames',{'start_sample','end_sample', ...
    'start_speed','end_speed','projected_transverse_area_scale', ...
    'liouville_transverse_area_scale','area_identity_residual', ...
    'autonomy_residual'});
result.energy_density_multiplier = 1./result.liouville_transverse_area_scale;
result.segment = returns.segment;
result = movevars(result,'segment','Before','start_sample');
writetable(result,fullfile(root,'data','photon_ray_tube.tsv'), ...
    'FileType','text','Delimiter','\t');

channel = result(strcmp(result.segment,'channel'),:);
fid = fopen(fullfile(root,'data','photon_maxwell_receipt.txt'),'w');
assert(fid ~= -1,'Unable to open photon receipt');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'PHOTON_RAY_TUBE_COMPATIBILITY\n');
fprintf(fid,'path_speed_min=%.17g\n',min(flow.speed(1176:1770)));
fprintf(fid,'path_speed_max=%.17g\n',max(flow.speed(1176:1770)));
fprintf(fid,'photon_clock=geometry_reparameterized_to_c\n');
fprintf(fid,'channel_projected_transverse_area_scale=%.17g\n',channel.projected_transverse_area_scale);
fprintf(fid,'channel_liouville_transverse_area_scale=%.17g\n',channel.liouville_transverse_area_scale);
fprintf(fid,'channel_area_identity_residual=%.17g\n',channel.area_identity_residual);
fprintf(fid,'channel_energy_density_multiplier=%.17g\n',channel.energy_density_multiplier);
fprintf(fid,'channel_autonomy_residual=%.17g\n',channel.autonomy_residual);
fprintf(fid,'local_poynting_realizability=algebraically_possible_after_geometry_reparameterization\n');
fprintf(fid,'steady_ray_tube_continuity=conditional_on_tangent_cocycle_accuracy\n');
fprintf(fid,'global_source_free_maxwell_field=unresolved\n');
fprintf(fid,'single_photon_null_field=unresolved\n');
clear cleanup

fprintf(['PHOTON_PROJECTED_AREA=%.17g LIOUVILLE_AREA=%.17g ' ...
    'AREA_RESIDUAL=%.17g DENSITY_MULTIPLIER=%.17g ' ...
    'AUTONOMY_RESIDUAL=%.17g\n'],channel.projected_transverse_area_scale, ...
    channel.liouville_transverse_area_scale,channel.area_identity_residual, ...
    channel.energy_density_multiplier,channel.autonomy_residual);
