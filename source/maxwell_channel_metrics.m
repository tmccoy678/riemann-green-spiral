function metric = maxwell_channel_metrics(channel,gridCount,tubeSigma,time)
tangent = zeros(size(channel));
tangent(2:end-1,:) = channel(3:end,:)-channel(1:end-2,:);
tangent(1,:) = channel(2,:)-channel(1,:);
tangent(end,:) = channel(end,:)-channel(end-1,:);
tangent = tangent./vecnorm(tangent,2,2);
padding = 3;
minimum = min(channel,[],1)-padding;
maximum = max(channel,[],1)+padding;
lengths = maximum-minimum;
axesValues = cell(3,1);
for axis = 1:3
    axesValues{axis} = minimum(axis)+(0:gridCount-1)*lengths(axis)/gridCount;
end
[X,Y,Z] = ndgrid(axesValues{1},axesValues{2},axesValues{3});
weight = zeros(size(X));
nx = zeros(size(X)); ny = nx; nz = nx;
for sample = 1:size(channel,1)
    d2 = (X-channel(sample,1)).^2+(Y-channel(sample,2)).^2+ ...
        (Z-channel(sample,3)).^2;
    local = exp(-d2/(2*tubeSigma^2));
    weight = weight+local;
    nx = nx+local*tangent(sample,1);
    ny = ny+local*tangent(sample,2);
    nz = nz+local*tangent(sample,3);
end
nmag = sqrt(nx.^2+ny.^2+nz.^2);
valid = nmag>1e-12;
nx(valid)=nx(valid)./nmag(valid); ny(valid)=ny(valid)./nmag(valid); nz(valid)=nz(valid)./nmag(valid);
amplitude = sqrt(weight/max(weight(:)));
ex = amplitude.*ny; ey = -amplitude.*nx; ez = zeros(size(ex));
degenerate = hypot(ex,ey)<1e-10 & valid;
ex(degenerate)=0; ey(degenerate)=amplitude(degenerate).*nz(degenerate); ez(degenerate)=-amplitude(degenerate).*ny(degenerate);
emag = sqrt(ex.^2+ey.^2+ez.^2); nonzero=emag>0;
ex(nonzero)=ex(nonzero)./emag(nonzero).*amplitude(nonzero);
ey(nonzero)=ey(nonzero)./emag(nonzero).*amplitude(nonzero);
ez(nonzero)=ez(nonzero)./emag(nonzero).*amplitude(nonzero);
[bx,by,bz] = crossComponents(nx,ny,nz,ex,ey,ez);
modes=[0:gridCount/2-1,-gridCount/2:-1];
[kx,ky,kz]=ndgrid(2*pi*modes/lengths(1),2*pi*modes/lengths(2),2*pi*modes/lengths(3));
[exk,eyk,ezk]=projectSolenoidal(fftn(ex),fftn(ey),fftn(ez),kx,ky,kz);
[bxk,byk,bzk]=projectSolenoidal(fftn(bx),fftn(by),fftn(bz),kx,ky,kz);
nyquist=abs(kx)==pi*gridCount/lengths(1)|abs(ky)==pi*gridCount/lengths(2)|abs(kz)==pi*gridCount/lengths(3);
exk(nyquist)=0;eyk(nyquist)=0;ezk(nyquist)=0;bxk(nyquist)=0;byk(nyquist)=0;bzk(nyquist)=0;
ex=real(ifftn(exk));ey=real(ifftn(eyk));ez=real(ifftn(ezk));
bx=real(ifftn(bxk));by=real(ifftn(byk));bz=real(ifftn(bzk));
[sx,sy,sz]=crossComponents(ex,ey,ez,bx,by,bz);
[alignment0,positive0]=tubeAlignment(sx,sy,sz,nx,ny,nz,weight);
energy0=0.5*sum(ex(:).^2+ey(:).^2+ez(:).^2+bx(:).^2+by(:).^2+bz(:).^2);
k=sqrt(kx.^2+ky.^2+kz.^2); cosine=cos(k*time); sine=zeros(size(k)); mask=k>0; sine(mask)=sin(k(mask)*time)./k(mask);
[kbx,kby,kbz]=crossComponents(kx,ky,kz,bxk,byk,bzk);
[kex,key,kez]=crossComponents(kx,ky,kz,exk,eyk,ezk);
extk=cosine.*exk+1i*sine.*kbx; eytk=cosine.*eyk+1i*sine.*kby; eztk=cosine.*ezk+1i*sine.*kbz;
bxtk=cosine.*bxk-1i*sine.*kex; bytk=cosine.*byk-1i*sine.*key; bztk=cosine.*bzk-1i*sine.*kez;
ext=real(ifftn(extk));eyt=real(ifftn(eytk));ezt=real(ifftn(eztk));
bxt=real(ifftn(bxtk));byt=real(ifftn(bytk));bzt=real(ifftn(bztk));
[sxt,syt,szt]=crossComponents(ext,eyt,ezt,bxt,byt,bzt);
[alignmentT,positiveT]=tubeAlignment(sxt,syt,szt,nx,ny,nz,weight);
energyT=0.5*sum(ext(:).^2+eyt(:).^2+ezt(:).^2+bxt(:).^2+byt(:).^2+bzt(:).^2);
metric=[gaussResidual(extk,eytk,eztk,kx,ky,kz),gaussResidual(bxtk,bytk,bztk,kx,ky,kz), ...
    abs(energyT-energy0)/energy0,alignment0,positive0,alignmentT,positiveT];
end

function [cx,cy,cz]=crossComponents(ax,ay,az,bx,by,bz)
cx=ay.*bz-az.*by;cy=az.*bx-ax.*bz;cz=ax.*by-ay.*bx;
end
function [vx,vy,vz]=projectSolenoidal(vx,vy,vz,kx,ky,kz)
k2=kx.^2+ky.^2+kz.^2; mask=k2>0; dot=kx.*vx+ky.*vy+kz.*vz; f=zeros(size(dot)); f(mask)=dot(mask)./k2(mask);
vx=vx-kx.*f;vy=vy-ky.*f;vz=vz-kz.*f;
end
function r=gaussResidual(vx,vy,vz,kx,ky,kz)
k2=kx.^2+ky.^2+kz.^2; d=1i*(kx.*vx+ky.*vy+kz.*vz); den=sqrt(sum(k2(:).*(abs(vx(:)).^2+abs(vy(:)).^2+abs(vz(:)).^2)));r=sqrt(sum(abs(d(:)).^2))/den;
end
function [a,p]=tubeAlignment(sx,sy,sz,nx,ny,nz,w)
m=sqrt(sx.^2+sy.^2+sz.^2); mask=w>0.2*max(w(:))&m>1e-12; q=zeros(size(w));q(mask)=(sx(mask).*nx(mask)+sy(mask).*ny(mask)+sz(mask).*nz(mask))./m(mask);a=sum(w(mask).*q(mask))/sum(w(mask));p=sum(w(mask).*(q(mask)>0))/sum(w(mask));
end
