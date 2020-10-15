function unzip_and_keep( volumeArray, par )
% unzip volumes, if needed.

%% Check input parameters

if ~exist('par','var'), par='';end

defpar.jobname = 'gunzip_and_keep';
defpar.redo    = 0;

par = complet_struct(par,defpar);


%% Establish list of files

volumes = volumeArray.removeEmpty;

% Keep only compressed volumes
% Making this first check improves computation time
isGZ = volumes.isGZ;
volumes = volumes(isGZ);

path_withGZ    = volumes.getPath;
volumes.removeGZ;
path_withoutGZ = volumes.getPath;

jobs = cell(size(volumes));
skip = [];
for vol = 1 : numel(volumes)
    
    if par.redo
        jobs{vol} = sprintf(                         'gunzip -f -k "%s"; \n',                      path_withGZ{vol});
        
    else
        if ~exist(path_withoutGZ{vol},'file') % i know its redontant, but it makes faster boths SGE=0 & SGE=1
            jobs{vol} = sprintf('if [ ! -e %s ]; then gunzip -f -k "%s"; fi \n', path_withoutGZ{vol}, path_withGZ{vol});
        else
            skip = [skip vol];
        end
        
    end
    
    
end % volume


%% Run CPU ! Run !

jobs(skip) = [];
do_cmd_sge(jobs,par);


end % function
