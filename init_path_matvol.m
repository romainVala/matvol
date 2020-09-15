function init_path_matvol

paths_to_add = regexp(genpath(matvoldir),pathsep,'split');
paths_to_add(end) = []; % the last one is always an empty split

regexp_to_take_out = {
    '\.git' % like the ".git/"
    };

for l =  1:length(regexp_to_take_out)
    where_cell = regexp(paths_to_add,regexp_to_take_out{l},'once');
    where_idx = cellfun( @isempty, where_cell, 'UniformOutput', 1);
    paths_to_add = paths_to_add(where_idx);
end

for p = 1 : length(paths_to_add)
    addpath(paths_to_add{p})
end


%for Warning with spm
spm('defaults','fmri')
spm_jobman('initcfg')
