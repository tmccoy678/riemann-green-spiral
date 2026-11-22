load wind
root = fileparts(fileparts(mfilename('fullpath')));
paths = readtable(fullfile(root,'data','riemann_paths.tsv'), ...
    'FileType','text','Delimiter','\t');
flow = readtable(fullfile(root,'data','path22_flow.tsv'), ...
    'FileType','text','Delimiter','\t');
spectrum = readtable(fullfile(root,'data','path22_spectrum.tsv'), ...
    'FileType','text','Delimiter','\t');
path22 = paths(paths.path_id == 22,:);

divGrid = divergence(x,y,z,u,v,w);
[curlXGrid,curlYGrid,curlZGrid] = curl(x,y,z,u,v,w);
divValue = interp3(x,y,z,divGrid,path22.x,path22.y,path22.z,'linear');
curlX = interp3(x,y,z,curlXGrid,path22.x,path22.y,path22.z,'linear');
curlY = interp3(x,y,z,curlYGrid,path22.x,path22.y,path22.z,'linear');
curlZ = interp3(x,y,z,curlZGrid,path22.x,path22.y,path22.z,'linear');
curlMagnitude = sqrt(curlX.^2+curlY.^2+curlZ.^2);

kinematics = table(path22.point_id,divValue,curlX,curlY,curlZ,curlMagnitude, ...
    'VariableNames',{'point_id','divergence','curl_x','curl_y','curl_z', ...
    'curl_magnitude'});
writetable(kinematics,fullfile(root,'data','path22_bohmian_kinematics.tsv'), ...
    'FileType','text','Delimiter','\t');

channelStart = 1176;
channelEnd = 1770;
point = [path22.x,path22.y,path22.z];
velocity = [flow.u,flow.v,flow.w];
delta = diff(point(channelStart:channelEnd,:));
midVelocity = (velocity(channelStart:channelEnd-1,:)+ ...
    velocity(channelStart+1:channelEnd,:))/2;
dt = sum(delta.*midVelocity,2)./sum(midVelocity.^2,2);
midDivergence = (divValue(channelStart:channelEnd-1)+ ...
    divValue(channelStart+1:channelEnd))/2;
integratedDivergence = sum(midDivergence.*dt);
densityLogCompensation = -integratedDivergence;

channelSpectrum = spectrum(strcmp(spectrum.segment,'channel'),:);
operatorLogDeterminant = channelSpectrum.transitions*log(channelSpectrum.determinant);
agreementResidual = integratedDivergence-operatorLogDeterminant;
channelCurl = curlMagnitude(channelStart:channelEnd);
channelDivergence = divValue(channelStart:channelEnd);

fid = fopen(fullfile(root,'data','bohmian_channel_kinematics_receipt.txt'),'w');
assert(fid ~= -1,'Unable to open kinematics receipt');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'BOHMIAN_CHANNEL_KINEMATICS_GRID_APPROXIMATION\n');
fprintf(fid,'status=superseded_for_flow_jacobian_by_path22_variational_returns.tsv\n');
fprintf(fid,'channel_start=%d\nchannel_end=%d\n',channelStart,channelEnd);
fprintf(fid,'integrated_divergence=%.17g\n',integratedDivergence);
fprintf(fid,'operator_log_determinant=%.17g\n',operatorLogDeterminant);
fprintf(fid,'agreement_residual=%.17g\n',agreementResidual);
fprintf(fid,'density_log_compensation=%.17g\n',densityLogCompensation);
fprintf(fid,'density_multiplier=%.17g\n',exp(densityLogCompensation));
fprintf(fid,'channel_curl_min=%.17g\n',min(channelCurl));
fprintf(fid,'channel_curl_median=%.17g\n',median(channelCurl));
fprintf(fid,'channel_curl_max=%.17g\n',max(channelCurl));
fprintf(fid,'channel_divergence_min=%.17g\n',min(channelDivergence));
fprintf(fid,'channel_divergence_median=%.17g\n',median(channelDivergence));
fprintf(fid,'channel_divergence_max=%.17g\n',max(channelDivergence));
fprintf(fid,'uniform_stationary_density=%d\n',all(abs(channelDivergence)<1e-10));
fprintf(fid,'vector_potential_required=%d\n',any(channelCurl>1e-10));
clear cleanup

fprintf(['INTEGRATED_DIVERGENCE=%.17g OPERATOR_LOG_DETERMINANT=%.17g ' ...
    'RESIDUAL=%.17g DENSITY_MULTIPLIER=%.17g CURL_MEDIAN=%.17g\n'], ...
    integratedDivergence,operatorLogDeterminant,agreementResidual, ...
    exp(densityLogCompensation),median(channelCurl));
