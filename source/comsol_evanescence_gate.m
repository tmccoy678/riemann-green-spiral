root = fileparts(fileparts(mfilename('fullpath')));
import com.comsol.model.*
import com.comsol.model.util.*

evanescence = readtable(fullfile(root,'data','local_evanescence.tsv'), ...
    'FileType','text','Delimiter','\t');
growth = readtable(fullfile(root,'data','gaussian_width_growth.tsv'), ...
    'FileType','text','Delimiter','\t');
selected = evanescence(strcmp(evanescence.ray,'normal_2_negative'),:);
selected = sortrows(selected,'cycle');
assert(isequal(selected.cycle,[7;8;9]),'Frozen cycle selection changed');
existingModels = cell(ModelUtil.tags);
if any(strcmp(existingModels,'EvanescenceMaxwell'))
    ModelUtil.remove('EvanescenceMaxwell');
end
if any(strcmp(existingModels,'EvanescenceDiffusion'))
    ModelUtil.remove('EvanescenceDiffusion');
end

%% Source-free scalar Maxwell realization
maxwell = ModelUtil.create('EvanescenceMaxwell');
maxwell.modelPath(root);
maxwell.label('Local evanescence scalar Maxwell gate');
maxwell.param.set('k0','3');
maxwell.param.set('kap',sprintf('%.17g',selected.kappa(1)));
maxwell.param.set('beta','sqrt(k0^2+kap^2)');
maxwell.component.create('comp1',true);
maxwell.component('comp1').geom.create('geom1',2);
maxwell.component('comp1').geom('geom1').create('r1','Rectangle');
maxwell.component('comp1').geom('geom1').feature('r1').set('size',{'1','1.4'});
maxwell.component('comp1').geom('geom1').run;
maxwell.component('comp1').physics.create('helm','CoefficientFormPDE','geom1');
maxwell.component('comp1').physics('helm').feature('cfeq1').set('c','1');
maxwell.component('comp1').physics('helm').feature('cfeq1').set('a','-k0^2');
maxwell.component('comp1').physics('helm').feature('cfeq1').set('f','0');
maxwell.component('comp1').physics('helm').create('dir1','DirichletBoundary',1);
maxwell.component('comp1').physics('helm').feature('dir1').selection.all;
maxwell.component('comp1').physics('helm').feature('dir1').set( ...
    'r','exp(-kap*y)*exp(i*beta*x)');
maxwell.component('comp1').mesh.create('mesh1');
maxwell.component('comp1').mesh('mesh1').autoMeshSize(3);
maxwell.study.create('std1');
maxwell.study('std1').create('stat','Stationary');

distance = (0.15:0.1:1.15)';
coordinates = [0.5*ones(1,numel(distance));distance'];
maxwellRows = zeros(3,8);
for index = 1:3
    maxwell.param.set('kap',sprintf('%.17g',selected.kappa(index)));
    maxwell.study('std1').run;
    field = mphinterp(maxwell,'u','coord',coordinates);
    forwardFlux = mphinterp(maxwell,'imag(conj(u)*ux)','coord',coordinates);
    amplitude = abs(field(:));
    fit = polyfit(distance,log(amplitude),1);
    predicted = polyval(fit,distance);
    total = sum((log(amplitude)-mean(log(amplitude))).^2);
    rSquared = 1-sum((log(amplitude)-predicted).^2)/total;
    kappa = -fit(1);
    monotonic = sum(diff(amplitude)<0)/(numel(amplitude)-1);
    forwardFraction = mean(forwardFlux(:)>0);
    relativeError = abs(kappa-selected.kappa(index))/selected.kappa(index);
    pass = kappa>0 && rSquared>=0.99 && monotonic>=0.8 && ...
        forwardFraction>=0.8 && relativeError<=0.01;
    maxwellRows(index,:) = [selected.cycle(index),kappa,rSquared, ...
        monotonic,forwardFraction,selected.kappa(index),relativeError,pass];
end
maxwellResult = array2table(maxwellRows,'VariableNames', ...
    {'cycle','comsol_kappa','exponential_r2','monotonic_fraction', ...
    'forward_flux_fraction','matlab_kappa','relative_error','pass'});

%% COMSOL diffusion realization of Gaussian widening
diffusion = ModelUtil.create('EvanescenceDiffusion');
diffusion.modelPath(root);
diffusion.label('Local Gaussian width diffusion gate');
q0 = growth.gaussian_q(1);
growthReceipt = fileread(fullfile(root,'data','gaussian_width_growth_receipt.txt'));
slopeToken = regexp(growthReceipt,'slope_per_arc=([^\n]+)','tokens','once');
assert(~isempty(slopeToken),'Missing frozen width-growth slope');
diffusivity = str2double(slopeToken{1})/2;
diffusion.param.set('q0',sprintf('%.17g',q0));
diffusion.param.set('D',sprintf('%.17g',diffusivity));
diffusion.component.create('comp1',true);
diffusion.component('comp1').geom.create('geom1',2);
diffusion.component('comp1').geom('geom1').create('r1','Rectangle');
diffusion.component('comp1').geom('geom1').feature('r1').set('size',{'1','12'});
diffusion.component('comp1').geom('geom1').feature('r1').set('pos',{'0','-6'});
diffusion.component('comp1').geom('geom1').run;
diffusion.component('comp1').physics.create('diff','CoefficientFormPDE','geom1');
diffusion.component('comp1').physics('diff').feature('cfeq1').set('da','1');
diffusion.component('comp1').physics('diff').feature('cfeq1').set('c','D');
diffusion.component('comp1').physics('diff').feature('cfeq1').set('f','0');
diffusion.component('comp1').physics('diff').feature('init1').set('u', ...
    'exp(-q0*y^2)');
diffusion.component('comp1').mesh.create('mesh1');
diffusion.component('comp1').mesh('mesh1').autoMeshSize(3);
diffusion.study.create('std1');
diffusion.study('std1').create('time','Transient');
diffusion.study('std1').feature('time').set('tlist',sprintf('%.17g %.17g %.17g', ...
    growth.arc_from_cycle_7(1),growth.arc_from_cycle_7(2), ...
    growth.arc_from_cycle_7(3)));
diffusion.study('std1').run;

normal = (0:0.1:1.5)';
coordinates = [0.5*ones(1,numel(normal));normal'];
diffusionRows = zeros(3,7);
for index = 1:3
    field = mphinterp(diffusion,'u','coord',coordinates, ...
        't',growth.arc_from_cycle_7(index));
    fit = polyfit(normal.^2,log(abs(field(:))),1);
    q = -fit(1);
    widthSquared = 1/(2*q);
    relativeError = abs(widthSquared-growth.width_squared(index))/ ...
        growth.width_squared(index);
    diffusionRows(index,:) = [growth.cycle(index), ...
        growth.arc_from_cycle_7(index),q,widthSquared, ...
        growth.width_squared(index),relativeError,relativeError<=0.01];
end
diffusionResult = array2table(diffusionRows,'VariableNames', ...
    {'cycle','arc_from_cycle_7','comsol_gaussian_q','comsol_width_squared', ...
    'matlab_width_squared','relative_error','within_one_percent'});
widthFit = polyfit(diffusionResult.arc_from_cycle_7, ...
    diffusionResult.comsol_width_squared,1);
widthPrediction = polyval(widthFit,diffusionResult.arc_from_cycle_7);
widthTotal = sum((diffusionResult.comsol_width_squared- ...
    mean(diffusionResult.comsol_width_squared)).^2);
widthR2 = 1-sum((diffusionResult.comsol_width_squared-widthPrediction).^2)/ ...
    widthTotal;
diffusionPass = widthFit(1)>0 && widthR2>=0.99 && ...
    all(diffusionResult.within_one_percent==1);

writetable(maxwellResult,fullfile(root,'data','comsol_evanescence.tsv'), ...
    'FileType','text','Delimiter','\t');
writetable(diffusionResult, ...
    fullfile(root,'data','comsol_gaussian_width_growth.tsv'), ...
    'FileType','text','Delimiter','\t');

version = mphversion(maxwell);
receiptPath = fullfile(root,'data','comsol_evanescence_receipt.txt');
fid = fopen(receiptPath,'w');
assert(fid~=-1,'Unable to open COMSOL receipt');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'COMSOL_EVANESCENCE_DIFFUSION_GATE\n');
fprintf(fid,'comsol_version=%s\n',version);
fprintf(fid,'maxwell_physics=source_free_scalar_helmholtz\n');
fprintf(fid,'maxwell_cycles=7,8,9\n');
fprintf(fid,'maxwell_pass=%d\n',all(maxwellResult.pass==1));
fprintf(fid,'maxwell_max_relative_kappa_error=%.17g\n', ...
    max(maxwellResult.relative_error));
fprintf(fid,'maxwell_min_exponential_r2=%.17g\n', ...
    min(maxwellResult.exponential_r2));
fprintf(fid,'maxwell_min_forward_flux_fraction=%.17g\n', ...
    min(maxwellResult.forward_flux_fraction));
fprintf(fid,'diffusion_slope_per_arc=%.17g\n',widthFit(1));
fprintf(fid,'diffusion_r_squared=%.17g\n',widthR2);
fprintf(fid,'diffusion_max_relative_width_error=%.17g\n', ...
    max(diffusionResult.relative_error));
fprintf(fid,'diffusion_pass=%d\n',diffusionPass);
fprintf(fid,'acceptance=%d\n',all(maxwellResult.pass==1) && diffusionPass);
clear cleanup

assert(all(maxwellResult.pass==1),'COMSOL Maxwell gate failed');
assert(diffusionPass,'COMSOL diffusion gate failed');
fprintf(['COMSOL_GATE_PASS=1 MAXWELL_MAX_ERROR=%.3e MAXWELL_MIN_R2=%.9f ' ...
    'DIFFUSION_SLOPE=%.12g DIFFUSION_R2=%.9f WIDTH_MAX_ERROR=%.3e\n'], ...
    max(maxwellResult.relative_error),min(maxwellResult.exponential_r2), ...
    widthFit(1),widthR2,max(diffusionResult.relative_error));

ModelUtil.remove('EvanescenceMaxwell');
ModelUtil.remove('EvanescenceDiffusion');
