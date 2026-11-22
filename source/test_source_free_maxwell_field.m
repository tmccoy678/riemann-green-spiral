root = fileparts(fileparts(mfilename('fullpath')));
paths = readtable(fullfile(root,'data','riemann_paths.tsv'), ...
    'FileType','text','Delimiter','\t');
path22 = paths(paths.path_id == 22,:);
channel = [path22.x(1176:1770),path22.y(1176:1770),path22.z(1176:1770)];
tangent = zeros(size(channel));
tangent(2:end-1,:) = channel(3:end,:)-channel(1:end-2,:);
tangent(1,:) = channel(2,:)-channel(1,:);
tangent(end,:) = channel(end,:)-channel(end-1,:);
tangent = tangent./vecnorm(tangent,2,2);

gridCount = 40;
padding = 3;
tubeSigma = 0.45;
minimum = min(channel,[],1)-padding;
maximum = max(channel,[],1)+padding;
lengths = maximum-minimum;
xAxis = minimum(1)+(0:gridCount-1)*lengths(1)/gridCount;
yAxis = minimum(2)+(0:gridCount-1)*lengths(2)/gridCount;
zAxis = minimum(3)+(0:gridCount-1)*lengths(3)/gridCount;
[X,Y,Z] = ndgrid(xAxis,yAxis,zAxis);

weight = zeros(size(X));
directionX = zeros(size(X));
directionY = zeros(size(X));
directionZ = zeros(size(X));
for sample = 1:size(channel,1)
    distanceSquared = (X-channel(sample,1)).^2+ ...
        (Y-channel(sample,2)).^2+(Z-channel(sample,3)).^2;
    localWeight = exp(-distanceSquared/(2*tubeSigma^2));
    weight = weight+localWeight;
    directionX = directionX+localWeight*tangent(sample,1);
    directionY = directionY+localWeight*tangent(sample,2);
    directionZ = directionZ+localWeight*tangent(sample,3);
end
directionMagnitude = sqrt(directionX.^2+directionY.^2+directionZ.^2);
validDirection = directionMagnitude>1e-12;
directionX(validDirection) = directionX(validDirection)./directionMagnitude(validDirection);
directionY(validDirection) = directionY(validDirection)./directionMagnitude(validDirection);
directionZ(validDirection) = directionZ(validDirection)./directionMagnitude(validDirection);

amplitude = sqrt(weight/max(weight(:)));
electricX = amplitude.*directionY;
electricY = -amplitude.*directionX;
electricZ = zeros(size(X));
degenerate = hypot(electricX,electricY)<1e-10 & validDirection;
electricX(degenerate) = 0;
electricY(degenerate) = amplitude(degenerate).*directionZ(degenerate);
electricZ(degenerate) = -amplitude(degenerate).*directionY(degenerate);
electricMagnitude = sqrt(electricX.^2+electricY.^2+electricZ.^2);
nonzeroElectric = electricMagnitude>0;
electricX(nonzeroElectric) = electricX(nonzeroElectric)./electricMagnitude(nonzeroElectric).*amplitude(nonzeroElectric);
electricY(nonzeroElectric) = electricY(nonzeroElectric)./electricMagnitude(nonzeroElectric).*amplitude(nonzeroElectric);
electricZ(nonzeroElectric) = electricZ(nonzeroElectric)./electricMagnitude(nonzeroElectric).*amplitude(nonzeroElectric);
[magneticX,magneticY,magneticZ] = crossComponents(directionX,directionY,directionZ, ...
    electricX,electricY,electricZ);

modes = [0:gridCount/2-1,-gridCount/2:-1];
[KX,KY,KZ] = ndgrid(2*pi*modes/lengths(1), ...
    2*pi*modes/lengths(2),2*pi*modes/lengths(3));
[electricXK,electricYK,electricZK] = projectSolenoidal( ...
    fftn(electricX),fftn(electricY),fftn(electricZ),KX,KY,KZ);
[magneticXK,magneticYK,magneticZK] = projectSolenoidal( ...
    fftn(magneticX),fftn(magneticY),fftn(magneticZ),KX,KY,KZ);
nyquist = abs(KX)==pi*gridCount/lengths(1) | ...
    abs(KY)==pi*gridCount/lengths(2) | abs(KZ)==pi*gridCount/lengths(3);
electricXK(nyquist) = 0; electricYK(nyquist) = 0; electricZK(nyquist) = 0;
magneticXK(nyquist) = 0; magneticYK(nyquist) = 0; magneticZK(nyquist) = 0;

electricX = real(ifftn(electricXK));
electricY = real(ifftn(electricYK));
electricZ = real(ifftn(electricZK));
magneticX = real(ifftn(magneticXK));
magneticY = real(ifftn(magneticYK));
magneticZ = real(ifftn(magneticZK));
[poyntingX,poyntingY,poyntingZ] = crossComponents(electricX,electricY,electricZ, ...
    magneticX,magneticY,magneticZ);
energy0 = 0.5*sum(electricX(:).^2+electricY(:).^2+electricZ(:).^2+ ...
    magneticX(:).^2+magneticY(:).^2+magneticZ(:).^2);
[alignment0,positiveFraction0] = tubeAlignment(poyntingX,poyntingY,poyntingZ, ...
    directionX,directionY,directionZ,weight);
gaussElectric0 = gaussResidual(electricXK,electricYK,electricZK,KX,KY,KZ);
gaussMagnetic0 = gaussResidual(magneticXK,magneticYK,magneticZK,KX,KY,KZ);

time = 0.2;
waveNumber = sqrt(KX.^2+KY.^2+KZ.^2);
cosine = cos(waveNumber*time);
sineOverK = zeros(size(waveNumber));
nonzeroK = waveNumber>0;
sineOverK(nonzeroK) = sin(waveNumber(nonzeroK)*time)./waveNumber(nonzeroK);
[kCrossBX,kCrossBY,kCrossBZ] = crossComponents(KX,KY,KZ, ...
    magneticXK,magneticYK,magneticZK);
[kCrossEX,kCrossEY,kCrossEZ] = crossComponents(KX,KY,KZ, ...
    electricXK,electricYK,electricZK);
electricXKT = cosine.*electricXK+1i*sineOverK.*kCrossBX;
electricYKT = cosine.*electricYK+1i*sineOverK.*kCrossBY;
electricZKT = cosine.*electricZK+1i*sineOverK.*kCrossBZ;
magneticXKT = cosine.*magneticXK-1i*sineOverK.*kCrossEX;
magneticYKT = cosine.*magneticYK-1i*sineOverK.*kCrossEY;
magneticZKT = cosine.*magneticZK-1i*sineOverK.*kCrossEZ;

electricXT = real(ifftn(electricXKT));
electricYT = real(ifftn(electricYKT));
electricZT = real(ifftn(electricZKT));
magneticXT = real(ifftn(magneticXKT));
magneticYT = real(ifftn(magneticYKT));
magneticZT = real(ifftn(magneticZKT));
[poyntingXT,poyntingYT,poyntingZT] = crossComponents(electricXT,electricYT,electricZT, ...
    magneticXT,magneticYT,magneticZT);
energyT = 0.5*sum(electricXT(:).^2+electricYT(:).^2+electricZT(:).^2+ ...
    magneticXT(:).^2+magneticYT(:).^2+magneticZT(:).^2);
[alignmentT,positiveFractionT] = tubeAlignment(poyntingXT,poyntingYT,poyntingZT, ...
    directionX,directionY,directionZ,weight);
gaussElectricT = gaussResidual(electricXKT,electricYKT,electricZKT,KX,KY,KZ);
gaussMagneticT = gaussResidual(magneticXKT,magneticYKT,magneticZKT,KX,KY,KZ);
energyResidual = abs(energyT-energy0)/energy0;

pass = gaussElectric0<1e-12 && gaussMagnetic0<1e-12 && ...
    gaussElectricT<1e-12 && gaussMagneticT<1e-12 && ...
    energyResidual<1e-10 && alignment0>0.5 && positiveFraction0>0.75;

fid = fopen(fullfile(root,'data','source_free_maxwell_receipt.txt'),'w');
assert(fid ~= -1,'Unable to open source-free Maxwell receipt');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'SOURCE_FREE_MAXWELL_FIELD\n');
fprintf(fid,'domain=periodic_vacuum\ngrid=%d^3\ncharges=0\ncurrents=0\n',gridCount);
fprintf(fid,'tube_sigma=%.17g\nevolution_time=%.17g\n',tubeSigma,time);
fprintf(fid,'gauss_electric_t0=%.17g\ngauss_magnetic_t0=%.17g\n',gaussElectric0,gaussMagnetic0);
fprintf(fid,'gauss_electric_t1=%.17g\ngauss_magnetic_t1=%.17g\n',gaussElectricT,gaussMagneticT);
fprintf(fid,'energy_relative_residual=%.17g\n',energyResidual);
fprintf(fid,'poynting_weighted_alignment_t0=%.17g\n',alignment0);
fprintf(fid,'poynting_positive_fraction_t0=%.17g\n',positiveFraction0);
fprintf(fid,'poynting_weighted_alignment_t1=%.17g\n',alignmentT);
fprintf(fid,'poynting_positive_fraction_t1=%.17g\n',positiveFractionT);
fprintf(fid,'acceptance=%d\n',pass);
fprintf(fid,'boundary=Constructed periodic source-free Maxwell field approximates the channel; it is not a unique inverse or proof of a one-photon state.\n');
clear cleanup

sliceIndex = round(gridCount/2);
poyntingMagnitude = sqrt(poyntingX.^2+poyntingY.^2+poyntingZ.^2);
figure('Color',[0.01 0.02 0.04],'Position',[100 100 1200 850]);
imagesc(yAxis,xAxis,squeeze(poyntingMagnitude(:,:,sliceIndex)));
set(gca,'YDir','normal','Color',[0.01 0.02 0.04], ...
    'XColor',[0.8 0.88 1],'YColor',[0.8 0.88 1],'FontSize',12);
axis image
colormap(turbo)
hold on
plot(channel(:,2),channel(:,1),'w-','LineWidth',1.2);
xlabel('y'); ylabel('x');
title({'Source-free Maxwell field','Poynting magnitude with Riemann channel projection'}, ...
    'Color',[0.94 0.97 1],'FontSize',17);
exportgraphics(gcf,fullfile(root,'artifacts','Source_Free_Maxwell_Riemann.png'), ...
    'Resolution',180);
close(gcf)

fprintf(['MAXWELL_PASS=%d GAUSS_E=%.3e GAUSS_B=%.3e ENERGY=%.3e ' ...
    'ALIGNMENT0=%.6f POSITIVE0=%.6f ALIGNMENT1=%.6f\n'],pass, ...
    gaussElectricT,gaussMagneticT,energyResidual,alignment0, ...
    positiveFraction0,alignmentT);

function [cx,cy,cz] = crossComponents(ax,ay,az,bx,by,bz)
cx = ay.*bz-az.*by;
cy = az.*bx-ax.*bz;
cz = ax.*by-ay.*bx;
end

function [vx,vy,vz] = projectSolenoidal(vx,vy,vz,kx,ky,kz)
kSquared = kx.^2+ky.^2+kz.^2;
nonzero = kSquared>0;
dotProduct = kx.*vx+ky.*vy+kz.*vz;
factor = zeros(size(dotProduct));
factor(nonzero) = dotProduct(nonzero)./kSquared(nonzero);
vx = vx-kx.*factor;
vy = vy-ky.*factor;
vz = vz-kz.*factor;
end

function residual = gaussResidual(vx,vy,vz,kx,ky,kz)
kSquared = kx.^2+ky.^2+kz.^2;
divergence = 1i*(kx.*vx+ky.*vy+kz.*vz);
denominator = sqrt(sum(kSquared(:).*(abs(vx(:)).^2+abs(vy(:)).^2+abs(vz(:)).^2)));
residual = sqrt(sum(abs(divergence(:)).^2))/denominator;
end

function [weightedAlignment,positiveFraction] = tubeAlignment(sx,sy,sz,nx,ny,nz,weight)
magnitude = sqrt(sx.^2+sy.^2+sz.^2);
mask = weight>0.2*max(weight(:)) & magnitude>1e-12;
alignment = zeros(size(weight));
alignment(mask) = (sx(mask).*nx(mask)+sy(mask).*ny(mask)+ ...
    sz(mask).*nz(mask))./magnitude(mask);
weightedAlignment = sum(weight(mask).*alignment(mask))/sum(weight(mask));
positiveFraction = sum(weight(mask).*(alignment(mask)>0))/sum(weight(mask));
end
