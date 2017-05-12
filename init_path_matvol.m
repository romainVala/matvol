function init_path

%make it short : include all subdir

dir_prog = [ fileparts(mfilename('fullpath')) filesep];
path(path,genpath(dir_prog));


%for Warning with spm2 and 5
spm('defaults','fmri')
spm_jobman('initcfg')


