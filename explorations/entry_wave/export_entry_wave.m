function export_entry_wave()
% Export the measured-field edge through the declared recurrent-channel entry.

load wind
backward_cell = stream3(x,y,z,-u,-v,-w,80,20,6);
backward = flipud(backward_cell{1});
assert(size(backward,1) == 36);

root = fileparts(fileparts(fileparts(mfilename('fullpath'))));
forward = readtable(fullfile(root,'data','path22_flow.tsv'), ...
    'FileType','text','Delimiter','\t');
capture_sample = 1176;
forward_xyz = [forward.x(2:capture_sample), ...
    forward.y(2:capture_sample), forward.z(2:capture_sample)];
entry = [backward; forward_xyz];

outdir = fullfile(root,'explorations','entry_wave','output');
if ~isfolder(outdir)
    mkdir(outdir);
end
output = fullfile(outdir,'path22_entry.tsv');
fid = fopen(output,'w');
assert(fid ~= -1,'Unable to open entry export');
cleanup = onCleanup(@() fclose(fid));
fprintf(fid,'point_id\tsource\tx\ty\tz\n');
seed_index = size(backward,1);
for i = 1:size(entry,1)
    if i < seed_index
        source = 'backtrace';
    elseif i == seed_index
        source = 'seed';
    elseif i == size(entry,1)
        source = 'channel_entry';
    else
        source = 'forward';
    end
    fprintf(fid,'%d\t%s\t%.17g\t%.17g\t%.17g\n', ...
        i,source,entry(i,1),entry(i,2),entry(i,3));
end

fprintf('ENTRY_POINTS=%d EDGE=(%.15g,%.15g,%.15g) SEED_INDEX=%d CAPTURE_SAMPLE=%d\n', ...
    size(entry,1),entry(1,1),entry(1,2),entry(1,3),seed_index,capture_sample);
end

