function init_path_matvol

%make it short : include all subdir

dir_prog = [ fileparts(mfilename('fullpath')) filesep];

paths_to_add_cell = regexp(genpath(dir_prog),':','split');
paths_to_add_cell(end) = []; % the last one is always an empty split

regexp_to_take_out = {
    '\.'
    };

for l =  1:length(regexp_to_take_out)
    where_cell = regexp(paths_to_add_cell,regexp_to_take_out{l},'once');
    where_idx = cellfun( @isempty, where_cell, 'UniformOutput', 1);
    paths_to_add_cell = paths_to_add_cell(where_idx);
end

paths_to_add_str = '';
for p = 1 : length(paths_to_add_cell)
    paths_to_add_str = [paths_to_add_str ':' paths_to_add_cell{p}];
end

path(paths_to_add_str,path);



%for Warning with spm
spm('defaults','fmri')
spm_jobman('initcfg')
