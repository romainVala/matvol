function zip_and_keep( volumeArray, par )
% unzip volumes, if needed.

%% Check input parameters

if ~exist('par','var'), par='';end

defpar.jobname = 'zip_and_keep';
defpar.redo    = 0;

par = complet_struct(par,defpar);


%% Establish list of files

volumes = volumeArray.removeEmpty;

path_withoutGZ = volumes.getPath;
path_withGZ    = strcat(path_withoutGZ,'.gz');

jobs = cell(size(volumes));
skip = [];
for vol = 1 : numel(volumes)
    
    if par.redo
        jobs{vol} = sprintf(                         'gzip -f -k "%s"; \n',                   path_withoutGZ{vol});
        
    else
        if ~exist(path_withGZ{vol},'file') % i know its redontant, but it makes faster boths SGE=0 & SGE=1
            jobs{vol} = sprintf('if [ ! -e %s ]; then gzip -f -k "%s"; fi \n', path_withGZ{vol}, path_withoutGZ{vol});
        else
            skip = [skip vol];
        end
        
    end
    
    
end % volume


%% Run CPU ! Run !

jobs(skip) = [];
do_cmd_sge(jobs,par);


end % function
