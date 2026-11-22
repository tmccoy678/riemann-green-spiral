root = fileparts(fileparts(mfilename('fullpath')));
a = 1;
b = 1;
c = sqrt(2)/2;
t0 = 10;

node = bohmNode(t0,a,b,c);
hTime = 1e-6;
nodeVelocity = (bohmNode(t0+hTime,a,b,c)-bohmNode(t0-hTime,a,b,c))/(2*hTime);
field = @(relative) bohmVelocity(node+relative,t0,a,b,c)-nodeVelocity;

options = optimoptions('lsqnonlin','Display','off','FunctionTolerance',1e-14, ...
    'StepTolerance',1e-14,'OptimalityTolerance',1e-14, ...
    'MaxIterations',300,'MaxFunctionEvaluations',2000);
[seedX,seedY] = meshgrid(-3:0.25:3,-3:0.25:3);
seeds = [seedX(:),seedY(:)];
seeds(vecnorm(seeds,2,2)<0.05,:) = [];
roots = zeros(0,2);
for k = 1:size(seeds,1)
    [candidate,resnorm,~,exitflag] = lsqnonlin(field,seeds(k,:),[-4,-4],[4,4],options);
    if exitflag > 0 && sqrt(resnorm) < 1e-8 && norm(candidate) > 1e-3
        if isempty(roots) || all(vecnorm(roots-candidate,2,2)>1e-5)
            roots(end+1,:) = candidate; %#ok<AGROW>
        end
    end
end

hSpace = 1e-5;
rootRows = zeros(size(roots,1),9);
for k = 1:size(roots,1)
    p = roots(k,:);
    J = zeros(2);
    J(:,1) = (field(p+[hSpace,0])-field(p-[hSpace,0]))'/(2*hSpace);
    J(:,2) = (field(p+[0,hSpace])-field(p-[0,hSpace]))'/(2*hSpace);
    values = eig(J);
    rootRows(k,:) = [k,p,norm(field(p)),reshape(J',1,4),prod(real(values))<0];
end
rootTable = array2table(rootRows,'VariableNames',{'root_id','relative_x', ...
    'relative_y','residual','j11','j12','j21','j22','is_saddle'});
writetable(rootTable,fullfile(root,'data','bohmian_electron_snapshot.tsv'), ...
    'FileType','text','Delimiter','\t');

saddles = find(rootTable.is_saddle == 1);
assert(~isempty(saddles),'No Bohmian X-point saddle found');
[~,nearestIndex] = min(vecnorm(roots(saddles,:),2,2));
xId = saddles(nearestIndex);
xPoint = roots(xId,:);

axisValues = linspace(-3,3,241);
[U,V] = meshgrid(axisValues,axisValues);
DU = nan(size(U));
DV = nan(size(V));
for k = 1:numel(U)
    if hypot(U(k),V(k)) > 0.04
        velocity = field([U(k),V(k)]);
        DU(k) = velocity(1);
        DV(k) = velocity(2);
    end
end

figure('Color',[0.015 0.025 0.045],'Position',[100 100 1100 900]);
streamslice(U,V,DU,DV,1.6);
set(findobj(gca,'Type','line'),'Color',[0.15 0.78 0.92]);
hold on
plot(0,0,'o','MarkerSize',13,'MarkerFaceColor',[0.50 1.00 0.45], ...
    'MarkerEdgeColor','none');
plot(xPoint(1),xPoint(2),'o','MarkerSize',12,'MarkerFaceColor',[1.00 0.63 0.18], ...
    'MarkerEdgeColor','none');
axis equal
xlim([-3 3]); ylim([-3 3]);
set(gca,'Color',[0.015 0.025 0.045],'XColor',[0.75 0.84 0.95], ...
    'YColor',[0.75 0.84 0.95],'FontSize',13,'LineWidth',1);
xlabel('u relative to moving node');
ylabel('v relative to moving node');
title({'One electron, three guiding modes', ...
    sprintf('Bohmian comoving flow at t = %.1f: node (green), X-point (orange)',t0)}, ...
    'Color',[0.92 0.96 1.00],'FontSize',18);
exportgraphics(gcf,fullfile(root,'artifacts','Bohmian_Electron_Node_X_Bridge.png'), ...
    'Resolution',180);
close(gcf)

fprintf(['NODE_X=%.17g NODE_Y=%.17g NODE_VX=%.17g NODE_VY=%.17g ' ...
    'ROOTS=%d X_RELATIVE_X=%.17g X_RELATIVE_Y=%.17g X_DISTANCE=%.17g\n'], ...
    node(1),node(2),nodeVelocity(1),nodeVelocity(2),height(rootTable), ...
    xPoint(1),xPoint(2),norm(xPoint));

function point = bohmNode(t,a,b,c)
point = [-sin((1+c)*t)/(a*sin(c*t)), ...
    -a*sin(t)/(b*sqrt(c)*sin((1+c)*t))];
end

function velocity = bohmVelocity(point,t,a,b,c)
x = point(1);
y = point(2);
phaseX = exp(-1i*t);
phaseXY = exp(-1i*(1+c)*t);
core = 1+a*x*phaseX+b*sqrt(c)*x*y*phaseXY;
dx = a*phaseX+b*sqrt(c)*y*phaseXY;
dy = b*sqrt(c)*x*phaseXY;
velocity = [imag(dx/core),imag(dy/core)];
end
