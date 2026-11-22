root=fileparts(fileparts(mfilename('fullpath')));
paths=readtable(fullfile(root,'data','riemann_paths.tsv'),'FileType','text','Delimiter','\t');
getPath=@(id) [paths.x(paths.path_id==id),paths.y(paths.path_id==id),paths.z(paths.path_id==id)];
riemann=getPath(22); riemann=riemann(1176:1376,:);
names={'riemann_return_1';'path_35';'path_27';'path_10';'straight_control'};
channels=cell(5,1); channels{1}=riemann;
for k=2:4
    ids=[35,27,10]; p=getPath(ids(k-1)); channels{k}=p(1:201,:);
end
t=linspace(0,1,201)'; channels{5}=riemann(1,:)+(riemann(end,:)-riemann(1,:)).*t;
rows=zeros(5,7);
for k=1:5, rows(k,:)=maxwell_channel_metrics(channels{k},32,0.45,0.2); end
result=array2table(rows,'VariableNames',{'gauss_e','gauss_b','energy_residual','alignment_t0','positive_t0','alignment_t1','positive_t1'});
result.channel=names;result=movevars(result,'channel','Before','gauss_e');
writetable(result,fullfile(root,'data','maxwell_controls.tsv'),'FileType','text','Delimiter','\t');
grids=[24;32;40]; convergence=zeros(3,8);
full=getPath(22);full=full(1176:1770,:);
for k=1:3, convergence(k,:)=[grids(k),maxwell_channel_metrics(full,grids(k),0.45,0.2)];end
conv=array2table(convergence,'VariableNames',{'grid','gauss_e','gauss_b','energy_residual','alignment_t0','positive_t0','alignment_t1','positive_t1'});
writetable(conv,fullfile(root,'data','maxwell_resolution.tsv'),'FileType','text','Delimiter','\t');
fprintf('RIEMANN_CONTROL_T1=%.9f CONTROL_MEDIAN_T1=%.9f GRID_RANGE_T1=%.9f..%.9f\n',result.alignment_t1(1),median(result.alignment_t1(2:end)),min(conv.alignment_t1),max(conv.alignment_t1));
